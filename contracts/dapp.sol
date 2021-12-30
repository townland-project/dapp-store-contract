// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {TownlandDAppOwnerRule} from "./rule.sol";

contract TownlandDAppStore is ERC1155, TownlandDAppOwnerRule {
    struct DApp {
        uint index; // dapp index
        string id; // dapp id
        string uri; // dapp manifest.json uri
        address owner; // dapp owner
    }

    uint Index = 0; // map index key
    uint Fee = 10; // price to add a DApp

    mapping(uint => bytes) IDs; // index => dapp id
    mapping(bytes => address) Owners; // dapp id => owner address
    mapping(bytes => uint) Indexs; // dapp id => index

    event OnDAppChange();
    event OnDAppFeeChange(uint fee);

    address payable self;

    constructor() ERC1155("") {
        self = payable(address(msg.sender));
    }

    modifier ValidIndex(uint index) {
        require(index != 0, "Index is zero.");
        require(index <= Index , "Index is not valid.");
        _;
    }

    modifier VerifyDAppID(string[] memory id) {
        require(id.length == 3, "DApp ID must have 3 part.");
        require(bytes(id[0]).length == 2 || bytes(id[0]).length == 3, "1st index need 2 or 3 character.");
        require(bytes(id[1]).length >= 3, "2nd index need more than 3 character.");
        require(bytes(id[2]).length >= 3, "3rd index need more than 3 character.");
        _;
    }

    function GetFee() public view returns (uint) {
        return Fee;
    }

    function GetLastIndex() public view returns (uint) {
        return Index;
    }

    function GetDAppByIndex(uint i) public view ValidIndex(i) returns (DApp memory) {
        return DApp(
                i,
                string(IDs[i]),
                GetUriOf(string(IDs[i])),
                Owners[IDs[i]]
            );   
    }

    function GetDApps() public view returns (DApp[] memory) {
        DApp[] memory apps = new DApp[](Index);

        // Index start from 1 but array start from 0
        for (uint i = 1; i <= Index; i++) {
            string memory id =  string(IDs[i]);
            //  array   = map
            apps[i - 1] = DApp(
                i,
                id,
                GetUriOf(id),
                Owners[bytes(id)]
            );
        }

        return apps;
    }

    function AddDApp(string[] calldata id) public payable VerifyDAppID(id) returns (uint256) {
        bytes memory _id = bytes(
            string(
                abi.encodePacked(id[0], ".", id[1], ".", id[2])
            )
        );

        require(Owners[_id] == address(0), "App ID registered.");

        if(GetOwner(msg.sender).rule == TownlandDAppOwnerRule.Rule.UNDEFINED) {
            require(msg.value == Fee, "Need coin for publish your app.");

            (bool success, ) = self.call{value: msg.value}("");
            require(success, "Failed to send coin.");
        }

        Index = Index + 1;

        IDs[Index] = _id;
        Owners[_id] = msg.sender;
        Indexs[_id] = Index;

        _mint(msg.sender, Index, 1, "");

        emit OnDAppChange();

        return Index;
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

    function uri(uint index) public view ValidIndex(index) override returns (string memory) {
        return GetUriOf(string(IDs[index]));
    }
}
