// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Author} from "./author.sol";
import {Application} from "./application.sol";

contract Store {
    Author.Database AuthorDB;
    Application.Database AppDB;

    address owner = msg.sender;

    function Publish(
        Author.Interface memory author,
        Application.Interface memory application
    ) public payable {
        require(
            Application.ExistID(AppDB, application.id),
            "This app id exists."
        );
        if (Author.Exist(AuthorDB, msg.sender) == false) {
            Author.Add(AuthorDB, author);
        }

        if (msg.sender == owner) {
            application.status = 3;
        } else {
            application.status = 0;
        }

        application.author = msg.sender;
        Application.Add(AppDB, application);
    }

    function GetApps() public view returns (Application.Interface[] memory) {
        return Application.GetAll(AppDB);
    }

    function GetAppsByStatus(int256 status)
        public
        view
        returns (Application.Interface[] memory)
    {
        return Application.GetAllByStatus(AppDB, status);
    }

    function GetAppById(string calldata id)
        public
        view
        returns (Application.Interface memory)
    {
        return Application.GetById(AppDB, id);
    }

    function GetAppsByAuthor(address author)
        public
        view
        returns (Application.Interface[] memory)
    {
        return Application.GetByAuthor(AppDB, author);
    }

    function GetMyApps() public view returns (Application.Interface[] memory) {
        return Application.GetByAuthor(AppDB, msg.sender);
    }

    function SetAppStatus(string calldata id, int256 status) public {
        require(
            msg.sender == owner,
            "Just contract owner can change app status"
        );
        Application.SetStatus(AppDB, id, status);
    }

    function UpdateAuthor(Author.Interface calldata author) public {
        Author.Update(AuthorDB, msg.sender, author);
    }

    function GetAuthors() public view returns (Author.Interface[] memory) {
        return Author.GetAll(AuthorDB);
    }

    function GetAuthorById(address id) public view returns (Author.Interface memory) {
        return Author.GetById(AuthorDB, id);
    }

    function GetMyAuthor() public view returns (Author.Interface memory) {
        return Author.GetById(AuthorDB, msg.sender);
    }
}
