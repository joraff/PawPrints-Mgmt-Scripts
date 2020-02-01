<?php

class historydb {

	var $server="gus.baylor.edu";
	var $name="print_history";
	var $user="username";
	var $pass="password";
	var $conn='';
	
	function historydb() {
		$this->conn = mysql_connect($this->server,$this->user,$this->pass);
		mysql_select_db($this->name, $this->conn);
	}
}

?>