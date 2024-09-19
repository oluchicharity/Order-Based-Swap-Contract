// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OrderBasedSwap {

    struct Order {
        address depositor;
        uint256 amountOffered;
        address tokenOffered;
        uint256 amountRequested;
        address tokenRequested;
        bool isCompleted;
    }

    mapping(uint256 => Order) public swapOrdersToUserAddress;
    uint256 public nextOrderId = 0;

    event CreateOrder(
        uint256 orderId, 
        address indexed depositor, 
        address tokenOffered, 
        uint256 amountOffered, 
        address tokenRequested, 
        uint256 amountRequested
    );
    
    event OrderFulfilled(uint256 orderId, address indexed fulfiller);

    function createOrder(
        address tokenOffered,
        address tokenRequested,
        uint256 amountOffered,
        uint256 amountRequested
    ) external {
        require(amountOffered > 0, "The amount you are offering must be greater than 0");
        require(amountRequested > 0, "Amount requested has to be greater than 0");

        IERC20(tokenOffered).transferFrom(msg.sender, address(this), amountOffered);

        swapOrdersToUserAddress[nextOrderId] = Order({
            depositor: msg.sender,
            tokenOffered: tokenOffered,
            amountOffered: amountOffered,
            tokenRequested: tokenRequested,
            amountRequested: amountRequested,
            isCompleted: false
        });

        emit CreateOrder(nextOrderId, msg.sender, tokenOffered, amountOffered, tokenRequested, amountRequested);

        nextOrderId++;
    }

    function initiateSwap(uint256 orderId) external {
        Order storage order = swapOrdersToUserAddress[orderId];

        require(!order.isCompleted, "This order has already been completed.");
        require(order.amountRequested > 0, "Invalid order.");

        IERC20(order.tokenRequested).transferFrom(msg.sender, order.depositor, order.amountRequested);

        IERC20(order.tokenOffered).transfer(msg.sender, order.amountOffered);

        order.isCompleted = true;

        emit OrderFulfilled(orderId, msg.sender);
    }
}
