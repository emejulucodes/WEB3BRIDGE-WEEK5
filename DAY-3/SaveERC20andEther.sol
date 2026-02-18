// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
	function transferFrom(address from, address to, uint256 amount) external returns (bool);
	function transfer(address to, uint256 amount) external returns (bool);
}

contract SaveERC20andEther {
	mapping(address => uint256) private etherSavings;
	mapping(address => mapping(address => uint256)) private tokenSavings;

	event EtherDeposited(address indexed user, uint256 amount);
	event EtherWithdrawn(address indexed user, uint256 amount);
	event TokenDeposited(address indexed user, address indexed token, uint256 amount);
	event TokenWithdrawn(address indexed user, address indexed token, uint256 amount);

	function depositEther() external payable {
		require(msg.value > 0, "Amount must be greater than zero");
		etherSavings[msg.sender] += msg.value;
		emit EtherDeposited(msg.sender, msg.value);
	}

	function withdrawEther(uint256 amount) external {
		require(amount > 0, "Amount must be greater than zero");
		require(etherSavings[msg.sender] >= amount, "Insufficient Ether savings");

		etherSavings[msg.sender] -= amount;
		(bool success, ) = payable(msg.sender).call{value: amount}("");
		require(success, "Ether transfer failed");

		emit EtherWithdrawn(msg.sender, amount);
	}

	function depositToken(address token, uint256 amount) external {
		require(token != address(0), "Invalid token address");
		require(amount > 0, "Amount must be greater than zero");

		bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
		require(success, "Token transferFrom failed");

		tokenSavings[msg.sender][token] += amount;
		emit TokenDeposited(msg.sender, token, amount);
	}

	function withdrawToken(address token, uint256 amount) external {
		require(token != address(0), "Invalid token address");
		require(amount > 0, "Amount must be greater than zero");
		require(tokenSavings[msg.sender][token] >= amount, "Insufficient token savings");

		tokenSavings[msg.sender][token] -= amount;
		bool success = IERC20(token).transfer(msg.sender, amount);
		require(success, "Token transfer failed");

		emit TokenWithdrawn(msg.sender, token, amount);
	}

	function getEtherBalance(address user) external view returns (uint256) {
		return etherSavings[user];
	}

	function getTokenBalance(address user, address token) external view returns (uint256) {
		return tokenSavings[user][token];
	}

	receive() external payable {
		require(msg.value > 0, "Amount must be greater than zero");
		etherSavings[msg.sender] += msg.value;
		emit EtherDeposited(msg.sender, msg.value);
	}
}
