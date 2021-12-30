// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {TownlandDAppOwnerRule} from "./rule.sol";

contract TownlandDAppStore is ERC1155, TownlandDAppOwnerRule {
    enum Status {
        REJECTED, // 0
        WAITING, // 1
        PUBLISHED // 2
    }

    struct App {
        bytes id; // app id like: xyz.townland.application
        Status status; // app registeration status
    }

    struct DApp {
        uint index; // dapp index
        string id; // dapp id
        string uri; // dapp manifest.json uri
        Status status; // dapp status
        address owner; // dapp owner
    }

    uint Index = 0; // map index key
    uint Fee = 10; // price to add a DApp

    mapping(uint => App) Apps;
    mapping(bytes => address) IDs;
    mapping(bytes => uint) Indexs;

    event OnDAppChange();
    event OnDAppFeeChange(uint fee);

    address payable self;

    constructor() ERC1155("") {
        self = payable(address(msg.sender));
    }

    modifier NotZeroIndex(uint index) {
        require(index != 0, "Index is zero.");
        _;
    }

    modifier VerifyDAppID(string[] memory id) {
        require(id.length == 3, "DApp ID must have 3 part.");
        require(bytes(id[0]).length == 2 || bytes(id[0]).length == 3, "1st index need 2 or 3 character.");
        require(bytes(id[1]).length >= 3, "2nd index need more than 3 character.");
        require(bytes(id[2]).length >= 3, "3rd index need more than 3 character.");
        _;
    }

    modifier VerifyDAppByIndex(uint index) {
        App memory app = Apps[index];

        require(IDs[app.id] != address(0), "DApp not found.");

        if(app.status == Status.REJECTED || app.status == Status.WAITING) {
            revert("DApp has not been published");
        }

        _;
    }

    function GetFee() public view returns (uint) {
        return Fee;
    }

    function GetIndex() public view returns (uint) {
        return Index;
    }

    function GetDAppByIndex(uint i) public view NotZeroIndex(i) returns (DApp memory) {
        string memory id =  string(Apps[i].id);

        return DApp(
                i,
                id,
                GetUriOf(id),
                Apps[i].status,
                IDs[Apps[i].id]
            );   
    }

    function GetDAppById(string calldata id) public view returns (DApp memory) {
        require(Indexs[bytes(id)] != 0, "DApp not found.");

        uint i = Indexs[bytes(id)];

        return DApp(
                i,
                id,
                GetUriOf(id),
                Apps[i].status,
                IDs[Apps[i].id]
            );   
    }

    function GetDApps() public view returns (DApp[] memory) {
        DApp[] memory apps = new DApp[](Index);

        // Index start from 1 but array start from 0
        for (uint i = 1; i <= Index; i++) {
            string memory id =  string(Apps[i].id);
            //  array   = map
            apps[i - 1] = DApp(
                i,
                id,
                GetUriOf(id),
                Apps[i].status,
                IDs[Apps[i].id]
            );
        }

        return apps;
    }

    function AddDApp(string[] calldata id) public payable VerifyDAppID(id) returns (uint256) {
        string memory _id = string(
            abi.encodePacked(id[0], ".", id[1], ".", id[2])
        );

        require(IDs[bytes(_id)] == address(0), "App ID registered.");

        Status status = Status.PUBLISHED;

        if(GetOwner(msg.sender).rule == TownlandDAppOwnerRule.Rule.UNDEFINED) {
            require(msg.value == Fee, "Need coin for publish your app.");

            (bool success, ) = self.call{value: msg.value}("");
            require(success, "Failed to send coin.");

            status = Status.WAITING;
        }

        Index = Index + 1;

        App memory app = App(bytes(_id), status);

        Apps[Index] = app;
        IDs[app.id] = msg.sender;
        Indexs[app.id] = Index;

        _mint(msg.sender, Index, 1, "");

        emit OnDAppChange();

        return Index;
    }

    function SetDAppStatusByIndex(uint index, Status status) public NotZeroIndex(index) OnlyOwnerWithRule(msg.sender, TownlandDAppOwnerRule.Admin) {
        Apps[index].status = status;

        emit OnDAppChange();
    }

    function SetDAppStatusByID(string calldata id, Status status) public {
        SetDAppStatusByIndex(Indexs[bytes(id)], status);
    }

    function SetFee(uint fee) public OnlyOwnerWithRule(msg.sender, TownlandDAppOwnerRule.Admin) {
        Fee = fee;

        emit OnDAppFeeChange(fee);
    }

    function GetUriOf(string memory id) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "https://dapp.townland.xyz/id/",
                    id,
                    "/manifest.json"
                )
            );
    }

    function uri(uint index) public view NotZeroIndex(index) VerifyDAppByIndex(index) override returns (string memory) {
        App memory app = Apps[index];

        return GetUriOf(string(app.id));
    }
}
