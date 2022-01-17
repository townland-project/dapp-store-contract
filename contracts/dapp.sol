// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import {TownlandOwnerRule} from "./rule.sol";

struct Config {
   uint AddFee;
   uint ChangeFee;
   string Gateway;
}

struct DApp {
    uint index;
    string id;
    string uri;
    address owner;
}

contract TownlandDApp is ERC721URIStorage, TownlandOwnerRule {

    // token id counter
    uint256 TokenID;

    address payable self;

    Config config = Config(10, 5, "cloudflare-ipfs.com");

    mapping(uint256 => bytes) IDs; // token id => dapp id
    mapping(bytes => uint256) TokenIDs; // dapp id => token id

    constructor() ERC721("TownlandDApp", "TDAPP") {
        self = payable(msg.sender);
    }

    function GetSelf() public view returns (address) {
        return self;
    }

    modifier VerifyDAppID(string[] memory id) {
        require(id.length == 3, "DApp ID must have 3 part.");
        require(
            bytes(id[0]).length == 2 || bytes(id[0]).length == 3,
            "1st index need 2 or 3 character."
        );
        require(
            bytes(id[1]).length >= 3,
            "2nd index need more than 3 character."
        );
        require(
            bytes(id[2]).length >= 3,
            "3rd index need more than 3 character."
        );
        _;
    }

    function GetDApps() public view returns(DApp[] memory) {
        DApp[] memory dapps = new DApp[](TokenID);

        for(uint i = 1; i <= TokenID; i++) {
            dapps[i - 1] = DApp(
                i,
                string(IDs[i]),
                tokenURI(i),
                ownerOf(i)  
            );
        }

        return dapps;
    }

    function pay(uint price) internal {
        if (GetOwner(msg.sender).rule == TownlandOwnerRule.Rule.UNDEFINED) {
            require(msg.value == price, "Need coin for your DApp.");

            (bool success,) = self.call{value: msg.value}("");
            require(success, "Failed sender coin.");
        }
    }

    function ipfs(string memory cid) public view returns(string memory) {
        return string(
            abi.encodePacked(
                "https://", config.Gateway, "/ipfs/", cid, "/manifest.json"
            )
        );
    }

    function Mint(string[] calldata id, string calldata cid)
        public
        payable
        VerifyDAppID(id)
    {
        bytes memory DAppID = bytes(
            string(abi.encodePacked(id[0], ".", id[1], ".", id[2]))
        );

        require(TokenIDs[DAppID] == 0, "DApp id registered.");

        pay(config.AddFee);

        TokenID = TokenID + 1;

        IDs[TokenID] = DAppID;
        TokenIDs[DAppID] = TokenID;

        _mint(msg.sender, TokenID); // sender is owner of this token id
        _setTokenURI(TokenID, ipfs(cid));
    }

    function Update(string calldata id, string calldata cid) public payable {
        bytes memory DAppID = bytes(id);
        uint256 _TokenID = TokenIDs[DAppID];
        require(ownerOf(_TokenID) == msg.sender, "DApp id did not register.");
        pay(config.ChangeFee);
        _setTokenURI(_TokenID, ipfs(cid));
    }

    function SetConfig(uint add, uint change, string calldata gateway) public OnlyOwnerWithRule(TownlandOwnerRule.Admin) {
        config = Config(add, change, gateway);
    }

    function GetConfig() public view returns (Config memory) {
        return config;
    }

    function PayBalance() public OnlyOwnerWithRule(TownlandOwnerRule.Admin) {
        (bool success, ) = msg.sender.call{value: self.balance}("");
        require(success, "Failed to send coin.");
    }
}
