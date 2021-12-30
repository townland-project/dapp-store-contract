// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {TownlandDAppOwnerRule} from "./rule.sol";

contract TownlandDAppStore is ERC1155, TownlandDAppOwnerRule {
    enum Status {
        REMOVED, // 0
        WAITING, // 1
        PUBLISHED // 2
    }

    struct App {
        bytes id; // app id like: xyz.townland.application
        Status status; // app registeration status
    }

    struct DApp {
        string id; // dapp id
        string uri; // dapp manifest.json uri
        Status status; // dapp status
        address owner; // dapp owner
    }

    uint Index = 0; // map index key
    uint Fee = 10; // price to add a DApp

    mapping(uint => App) Apps;
    mapping(bytes => address) IDs;

    event OnDAppAdded(uint index, string id);
    event OnDAppStatusChange(uint index, Status status);
    event OnDAppFeeChange(uint fee);

    address payable self;

    constructor() ERC1155("") {
        self = payable(address(msg.sender));
    }

    function StrLen(string memory str) internal pure returns (uint) {
        return bytes(str).length;
    }

    modifier VerifyDAppID(string[] memory id) {
        require(id.length == 3, "DApp ID must have 3 part.");
        require(StrLen(id[0]) == 2 || StrLen(id[0]) == 3, "1st index need 2 or 3 character.");
        require(StrLen(id[1]) >= 3, "2nd index need more than 3 character.");
        require(StrLen(id[2]) >= 3, "3rd index need more than 3 character.");
        _;
    }

    modifier VerifyDAppByIndex(uint index) {
        App memory app = Apps[index];

        require(IDs[app.id] != address(0), "App not found.");

        if(app.status == Status.REMOVED || app.status == Status.WAITING) {
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

    function GetDApps() public view returns (DApp[] memory) {
        DApp[] memory apps = new DApp[](Index);

        for (uint i = 0; i < Index; i++) {
            string memory id =  string(Apps[i + 1].id);
            //  array   = map
            apps[i] = DApp(
                id,
                GetUriOf(id),
                Apps[i+1].status,
                IDs[Apps[i+1].id]
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

        _mint(msg.sender, Index, 1, "");

        emit OnDAppAdded(Index, _id);

        return Index;
    }

    function SetDAppStatus(uint index, Status status) public OnlyOwnerWithRule(msg.sender, TownlandDAppOwnerRule.AdminAndRoot) {
        Apps[index].status = status;

        emit OnDAppStatusChange(index, status);
    }

    function SetFee(uint fee) public OnlyOwnerWithRule(msg.sender, TownlandDAppOwnerRule.AdminAndRoot) {
        Fee = fee;

        emit OnDAppFeeChange(fee);
    }

    function GetPaidFee() public view returns (uint) {
        return self.balance;
    }

    function GivePaidFee() public OnlyOwnerWithRule(msg.sender, TownlandDAppOwnerRule.AdminAndRoot) {
        (bool success, ) = msg.sender.call{value: self.balance}("");
        require(success, "Failed to send fee.");
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

    function uri(uint index) public view VerifyDAppByIndex(index) override returns (string memory) {
        App memory app = Apps[index];

        return GetUriOf(string(app.id));
    }
}
