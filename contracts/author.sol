// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library Author {
    struct Database {
        address[] Keys; // array of authors id
        mapping(address => Interface) Map; // map of authors
    }

    struct Interface {
        address id; // author unique id
        string avatar; // author avatar image url
        string name; // author name or company name
        string email; // author email address for support
        string url; // author website home page
    }

    function Exist(Database storage database, address id)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < database.Keys.length; i++) {
            address _id = database.Keys[i];

            if (_id == id) {
                return true;
            }
        }

        return false;
    }

    function Add(Database storage database, Interface memory data) public {
        database.Keys.push(data.id);
        database.Map[data.id] = data;
    }

    function Update(
        Database storage database,
        address id,
        Interface memory data
    ) public {
        database.Map[id] = data;
    }

    function GetAll(Database storage database)
        public
        view
        returns (Interface[] memory)
    {
        Interface[] memory authors = new Interface[](database.Keys.length);

        for (uint256 i = 0; i < database.Keys.length; i++) {
            authors[i] = database.Map[database.Keys[i]];
        }

        return authors;
    }

    function GetById(Database storage database, address id)
        public
        view
        returns (Interface memory)
    {
        return database.Map[id];
    }
}
