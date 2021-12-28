// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library Application {
    struct Database {
        StatusCount Status;
        string[] Keys; // array of apps id
        mapping(string => Interface) Map; // map of application
    }

    // count status
    struct StatusCount {
        uint256 preinstalled; // app that can preinstalled => 3
        uint256 verified; // published and have verified symbol => 2
        uint256 published; // app published => 1
        uint256 waiting; // app is in waiting state => 0
        uint256 removed; // app removed => -1
    }

    struct Interface {
        string id; // app id like : xyz.townland.application
        string name; // app name
        string url; // app http url (ipfs/github page/...)
        string icon; // app icon
        string version; // app version
        string description; // app description
        string[] keywords; // app keywords for searching
        string category; // app category
        address author; // author id
        int256 status; // app stauts
    }

    function ExistID(Database storage database, string calldata id)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < database.Keys.length; i++) {
            string memory _id = database.Keys[i];

            if (
                keccak256(abi.encodePacked(_id)) ==
                keccak256(abi.encodePacked(id))
            ) {
                return true;
            }
        }

        return false;
    }

    function Add(Database storage database, Interface memory data) public {
        database.Keys.push(data.id);
        database.Map[data.id] = data;
        if (data.status == 3) {
            database.Status.preinstalled++;
        } else {
            database.Status.waiting++;
        }
    }

    function GetAll(Database storage database)
        public
        view
        returns (Interface[] memory)
    {
        Interface[] memory apps = new Interface[](database.Keys.length);

        for (uint256 i = 0; i < database.Keys.length; i++) {
            apps[i] = database.Map[database.Keys[i]];
        }

        return apps;
    }

    function GetAllByStatus(Database storage database, int256 status)
        public
        view
        returns (Interface[] memory)
    {
        uint256 count = 0;
        if (status == -1) count = database.Status.removed;
        else if (status == 0) count = database.Status.waiting;
        else if (status == 1) count = database.Status.published;
        else if (status == 2) count = database.Status.verified;
        else if (status == 3) count = database.Status.preinstalled;
        uint256 index = 0;
        Interface[] memory apps = new Interface[](count);

        for (uint256 i = 0; i < database.Keys.length; i++) {
            if (database.Map[database.Keys[i]].status == status) {
                apps[index] = database.Map[database.Keys[i]];
                index++;
            }
        }

        return apps;
    }

    function GetById(Database storage database, string memory id)
        public
        view
        returns (Interface memory)
    {
        return database.Map[id];
    }

    function GetByAuthor(Database storage database, address id)
        public
        view
        returns (Interface[] memory)
    {
        uint256 count = CountByAuthor(database, id);

        if (count != 0) {
            uint256 index = 0;
            Interface[] memory apps = new Interface[](count);

            for (uint256 i = 0; i < database.Keys.length; i++) {
                if (database.Map[database.Keys[i]].author == id) {
                    apps[index] = database.Map[database.Keys[i]];
                    index++;
                }
            }

            return apps;
        }
        return new Interface[](0);
    }

    function GetByCategory(Database storage database, string memory category)
        public
        view
        returns (Interface[] memory)
    {
        uint256 count = CountByCategory(database, category);

        if (count != 0) {
            uint256 index = 0;
            Interface[] memory apps = new Interface[](count);

            for (uint256 i = 0; i < database.Keys.length; i++) {
                if (
                    keccak256(
                        abi.encodePacked(
                            database.Map[database.Keys[i]].category
                        )
                    ) == keccak256(abi.encodePacked(category))
                ) {
                    apps[index] = database.Map[database.Keys[i]];
                    index++;
                }
            }

            return apps;
        }
        return new Interface[](0);
    }

    function CountByAuthor(Database storage database, address id)
        public
        view
        returns (uint256)
    {
        uint256 count = 0;

        for (uint256 i = 0; i < database.Keys.length; i++) {
            if (database.Map[database.Keys[i]].author == id) {
                count++;
            }
        }

        return count;
    }

    function CountByCategory(Database storage database, string memory category)
        public
        view
        returns (uint256)
    {
        uint256 count = 0;

        for (uint256 i = 0; i < database.Keys.length; i++) {
            if (
                keccak256(
                    abi.encodePacked(database.Map[database.Keys[i]].category)
                ) == keccak256(abi.encodePacked(category))
            ) {
                count++;
            }
        }

        return count;
    }

    function SetStatus(
        Database storage database,
        string memory id,
        int256 status
    ) public {
        int256 current = database.Map[id].status;

        if (current == -1) database.Status.removed--;
        else if (current == 0) database.Status.waiting--;
        else if (current == 1) database.Status.published--;
        else if (current == 2) database.Status.verified--;
        else if (current == 3) database.Status.preinstalled--;
        else {}

        if (status == -1) database.Status.removed++;
        else if (status == 0) database.Status.waiting++;
        else if (status == 1) database.Status.published++;
        else if (status == 2) database.Status.verified++;
        else if (status == 3) database.Status.preinstalled++;
        else {}

        database.Map[id].status = status;
    }
}
