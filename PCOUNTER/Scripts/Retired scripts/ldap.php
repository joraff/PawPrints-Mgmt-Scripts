<?php

	$ldcon = ldap_connect("baylor.edu");
	$bind = ldap_bind($ldcon, "CN=Web_Query,OU=ITC,OU=BU Service Accounts,DC=baylor,DC=edu","connecting*people");
	/*$sr=ldap_search($ldcon,"ou=BU Groups,dc=baylor, dc=edu", "CN=G Law Student Paw"); 
	$info = ldap_get_entries($ldcon, $sr);
		
		$laws = array();
		
	foreach($info[0]['member'] as $member) {
		preg_match('/CN=([^,]+)/', $member, $str);
		echo $str[1]."\n";
		$laws[] = $str[1];
	}
	*/
	
	$sr=ldap_search($ldcon,"ou=All Users,ou=BU Users,dc=baylor,dc=edu", "(&(cn>=ja)(cn<=jo))"); 
	$info = ldap_get_entries($ldcon, $sr);
	
	print_r($info[0]['member']);
?>
	
