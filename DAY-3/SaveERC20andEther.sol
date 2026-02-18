// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
	function transfer(address to, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract SaveERC20andEther {
	mapping(address account => uint256) private etherBalances;
	mapping(address account => mapping(address token => uint256)) private tokenBalances;

	event EtherDeposited(address indexed user, uint256 amount);
	event EtherWithdrawn(address indexed user, uint256 amount);
	event TokenDeposited(address indexed user, address indexed token, uint256 amount);
	event TokenWithdrawn(address indexed user, address indexed token, uint256 amount);

	function depositEther() external payable {
		require(msg.value > 0, "Cannot deposit zero ether");

		etherBalances[msg.sender] += msg.value;
		emit EtherDeposited(msg.sender, msg.value);
	}

	function withdrawEther(uint256 amount) external {
		require(amount > 0, "Cannot withdraw zero ether");

		uint256 userBalance = etherBalances[msg.sender];
		require(userBalance >= amount, "Insufficient ether balance");

		unchecked {
			etherBalances[msg.sender] = userBalance - amount;
		}

		(bool success, ) = payable(msg.sender).call{value: amount}("");
		require(success, "Ether transfer failed");

		emit EtherWithdrawn(msg.sender, amount);
	}

	function depositToken(address token, uint256 amount) external {
		require(token != address(0), "Invalid token address");
		require(amount > 0, "Cannot deposit zero token");

		bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
		require(success, "Token transfer failed");

		tokenBalances[msg.sender][token] += amount;
		emit TokenDeposited(msg.sender, token, amount);
	}

	function withdrawToken(address token, uint256 amount) external {
		require(token != address(0), "Invalid token address");
		require(amount > 0, "Cannot withdraw zero token");

		uint256 userBalance = tokenBalances[msg.sender][token];
		require(userBalance >= amount, "Insufficient token balance");

		unchecked {
			tokenBalances[msg.sender][token] = userBalance - amount;
		}

		bool success = IERC20(token).transfer(msg.sender, amount);
		require(success, "Token withdrawal failed");

		emit TokenWithdrawn(msg.sender, token, amount);
	}

	function getEtherBalance(address user) external view returns (uint256) {
		return etherBalances[user];
	}

	function getTokenBalance(address user, address token) external view returns (uint256) {
		return tokenBalances[user][token];
	}

	function getMyEtherBalance() external view returns (uint256) {
		return etherBalances[msg.sender];
	}

	function getMyTokenBalance(address token) external view returns (uint256) {
		return tokenBalances[msg.sender][token];
	}

	function getContractEtherBalance() external view returns (uint256) {
		return address(this).balance;
	}

	receive() external payable {
		etherBalances[msg.sender] += msg.value;
		emit EtherDeposited(msg.sender, msg.value);
	}
}
