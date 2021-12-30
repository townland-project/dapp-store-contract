// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TownlandDAppOwnerRule {
    enum Rule {
        UNDEFINED, // 0
        ROOT, // 1
        ADMIN // 2
    }

    struct Database {
        address[] OwnersAddress; // list of owners' address
        mapping(address=>Rule) Owners; // map of owners with thier rule
    }

    struct Owner {
        Rule rule;
        address user;
    }

    event OnOwnerAdded(address user, Rule rule);
    event OnOwnerChanged(address user, Rule rule);

    Rule[] AdminAndRoot = [Rule.ROOT, Rule.ADMIN];

    Database database;

    constructor() {
        database.OwnersAddress.push(msg.sender);
        database.Owners[msg.sender] = Rule.ROOT;
    }

    modifier OnlyOwnerWithRule(address user, Rule[] memory rules) {
        require(database.Owners[user] != Rule.UNDEFINED, "Who are you ?");

        bool has = false;

        for(uint i = 0; i < rules.length; i++) {
            if(database.Owners[user] == rules[i]) {
                has = true;
            }
        }
        if(has) {
            _;
        } else {
            revert("Dear owner you don't have permission.");
        }
    }

    function AddOwner(address user, Rule rule) public OnlyOwnerWithRule(msg.sender, AdminAndRoot) {
        require(rule != Rule.ROOT, "Just one root.");
        database.OwnersAddress.push(user);
        SetOwnerRule(user, rule);
        emit OnOwnerAdded(user, rule);
    }

    function SetOwnerRule(address user, Rule rule) public OnlyOwnerWithRule(msg.sender, AdminAndRoot) {
        database.Owners[user] = rule;
        emit OnOwnerChanged(user, rule);
    }

    function GetOwner(address user) public view returns (Owner memory) {
        Owner memory owner;

        owner.user = user;
        owner.rule = database.Owners[user];

        return owner;
    }

    function GetOwners() public view returns (Owner[] memory) {
        Owner[] memory owners = new Owner[](database.OwnersAddress.length);

        for(uint i = 0 ; i < database.OwnersAddress.length; i++) {
            owners[i] = GetOwner(database.OwnersAddress[i]);
        }

        return owners;
    }

    function IsOwner(address user) public view returns (bool) {
        return database.Owners[user] != Rule.UNDEFINED;
    }

    function AmIOwner() public view returns (bool) {
        return IsOwner(msg.sender);
    }
}