// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
	function transfer(address to, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract SchoolManagment {
	IERC20 public constant EMCDS = IERC20(0xDf377902d015e7dA5d60190073cA20B370b97BFE);

	address public immutable owner;

	struct Student {
		uint256 id;
		address account;
		string fullName;
		uint16 level;
		uint256 schoolFee;
		bool paymentStatus;
		uint256 paymentTimestamp;
	}

	struct Staff {
		uint256 id;
		address account;
		string fullName;
		string role;
		bool isPaid;
		uint256 totalPaid;
		uint256 paymentTimestamp;
	}

	uint256 public nextStudentId;
	uint256 public nextStaffId;

	mapping(uint16 level => uint256 fee) public levelToSchoolFee;
	mapping(address student => Student) private students;
	mapping(address staff => Staff) private staffs;

	address[] private studentAccounts;
	address[] private staffAccounts;

	event StudentRegistered(
		uint256 indexed studentId,
		address indexed student,
		string fullName,
		uint16 level,
		uint256 feeAmount,
		uint256 paidAt
	);

	event StaffRegistered(
		uint256 indexed staffId,
		address indexed staff,
		string fullName,
		string role
	);

	event StaffPaid(address indexed staff, uint256 amount, uint256 paidAt);
	event SchoolFeeUpdated(uint16 indexed level, uint256 amount);

	modifier onlyOwner() {
		require(msg.sender == owner, "Only owner can call");
		_;
	}

	constructor(
		uint256 fee100Level,
		uint256 fee200Level,
		uint256 fee300Level,
		uint256 fee400Level
	) {
		owner = msg.sender;

		levelToSchoolFee[100] = fee100Level;
		levelToSchoolFee[200] = fee200Level;
		levelToSchoolFee[300] = fee300Level;
		levelToSchoolFee[400] = fee400Level;
	}

	function registerStudent(address student, string calldata fullName, uint16 level) external {
		require(student != address(0), "Invalid student address");
		require(bytes(fullName).length > 0, "Name is required");
		require(students[student].account == address(0), "Student already registered");
		require(level == 100 || level == 200 || level == 300 || level == 400, "Invalid level");

		uint256 feeAmount = levelToSchoolFee[level];
		require(feeAmount > 0, "Fee not set for level");

		bool success = EMCDS.transferFrom(msg.sender, address(this), feeAmount);
		require(success, "School fee payment failed");

		nextStudentId += 1;
		students[student] = Student({
			id: nextStudentId,
			account: student,
			fullName: fullName,
			level: level,
			schoolFee: feeAmount,
			paymentStatus: true,
			paymentTimestamp: block.timestamp
		});

		studentAccounts.push(student);

		emit StudentRegistered(nextStudentId, student, fullName, level, feeAmount, block.timestamp);
	}

	function registerStaff(address staff, string calldata fullName, string calldata role) external onlyOwner {
		require(staff != address(0), "Invalid staff address");
		require(bytes(fullName).length > 0, "Name is required");
		require(bytes(role).length > 0, "Role is required");
		require(staffs[staff].account == address(0), "Staff already registered");

		nextStaffId += 1;
		staffs[staff] = Staff({
			id: nextStaffId,
			account: staff,
			fullName: fullName,
			role: role,
			isPaid: false,
			totalPaid: 0,
			paymentTimestamp: 0
		});

		staffAccounts.push(staff);

		emit StaffRegistered(nextStaffId, staff, fullName, role);
	}

	function payStaff(address staff, uint256 amount) external onlyOwner {
		require(staff != address(0), "Invalid staff address");
		require(amount > 0, "Amount must be greater than zero");
		require(staffs[staff].account != address(0), "Staff not registered");

		bool success = EMCDS.transfer(staff, amount);
		require(success, "Staff payment failed");

		staffs[staff].isPaid = true;
		staffs[staff].totalPaid += amount;
		staffs[staff].paymentTimestamp = block.timestamp;

		emit StaffPaid(staff, amount, block.timestamp);
	}

	function updateSchoolFee(uint16 level, uint256 amount) external onlyOwner {
		require(level == 100 || level == 200 || level == 300 || level == 400, "Invalid level");
		require(amount > 0, "Fee must be greater than zero");

		levelToSchoolFee[level] = amount;
		emit SchoolFeeUpdated(level, amount);
	}

	function getStudent(address student) external view returns (Student memory) {
		require(students[student].account != address(0), "Student not registered");
		return students[student];
	}

	function getAllStudents() external view returns (Student[] memory) {
		uint256 totalStudents = studentAccounts.length;
		Student[] memory allStudents = new Student[](totalStudents);

		for (uint256 i; i < totalStudents; i++) {
			allStudents[i] = students[studentAccounts[i]];
		}

		return allStudents;
	}

	function getStaff(address staff) external view returns (Staff memory) {
		require(staffs[staff].account != address(0), "Staff not registered");
		return staffs[staff];
	}

	function getAllStaffs() external view returns (Staff[] memory) {
		uint256 totalStaffs = staffAccounts.length;
		Staff[] memory allStaffs = new Staff[](totalStaffs);

		for (uint256 i; i < totalStaffs; i++) {
			allStaffs[i] = staffs[staffAccounts[i]];
		}

		return allStaffs;
	}

	function getContractEMCDSBalance() external view returns (uint256) {
		return address(EMCDS).code.length > 0 ? _safeTokenBalance() : 0;
	}

	function _safeTokenBalance() internal view returns (uint256 balance) {
		(bool success, bytes memory data) = address(EMCDS).staticcall(
			abi.encodeWithSignature("balanceOf(address)", address(this))
		);
		require(success && data.length >= 32, "Could not fetch balance");
		balance = abi.decode(data, (uint256));
	}
}
