<?php

return [
    'Base DN' => 'Osnovni DN',
    'Defines the filter to apply, when login is attempted. %s replaces the username in the login action. Example: &quot;(sAMAccountName=%s)&quot; or &quot;(uid=%s)&quot;' => 'Određuje filtar koji se primjenjuje kod pokušajaj prijave. %s zamjenjuje korisničko ime u akciji za prijavu. Primjer: "(sAMAccountName=%s)" ili "(uid=%s)"',
    'E-Mail Address Attribute' => 'Atribut E-mail adrese',
    'Enable LDAP Support' => 'Omogući LDAP podršku',
    'Encryption' => 'Enkripcija',
    'Fetch/Update Users Automatically' => 'Dohvaćanje / Ažuriranje korisnika automatski',
    'Hostname' => 'Hostname',
    'ID Attribute' => 'ID atribut',
    'LDAP' => 'LDAP',
    'LDAP Attribute for E-Mail Address. Default: &quot;mail&quot;' => 'LDAP Attribute for E-Mail Address. Default: "mail"',
    'LDAP Attribute for Username. Example: &quot;uid&quot; or &quot;sAMAccountName&quot;' => 'LDAP Attribute for Username. Example: "uid" or "sAMAccountName"',
    'Limit access to users meeting this criteria. Example: &quot;(objectClass=posixAccount)&quot; or &quot;(&(objectClass=person)(memberOf=CN=Workers,CN=Users,DC=myDomain,DC=com))&quot;' => 'Limit access to users meeting this criteria. Example: "(objectClass=posixAccount)" or "(&amp;(objectClass=person)(memberOf=CN=Workers,CN=Users,DC=myDomain,DC=com))"',
    'Login Filter' => 'Filter za prijavu',
    'Not changeable LDAP attribute to unambiguously identify the user in the directory. If empty the user will be determined automatically by e-mail address or username. Examples: objectguid (ActiveDirectory) or uidNumber (OpenLDAP)' => 'Not changeable LDAP attribute to unambiguously identify the user in the directory. If empty the user will be determined automatically by e-mail address or username. Examples: objectguid (ActiveDirectory) or uidNumber (OpenLDAP)',
    'Password' => 'Lozinka',
    'Port' => 'Port',
    'Specify your LDAP-backend used to fetch user accounts.' => 'Navedite svoj LDAP-backend koji se koristi za dobavljanje korisničkih računa.',
    'Status: Error! (Message: {message})' => 'Status: Greška! (Poruka: {message})',
    'Status: OK! ({userCount} Users)' => 'Status: OK! ({userCount} Korisnici)',
    'Status: Warning! (No users found using the ldap user filter!)' => 'Status: Upozorenje! (Nisu pronađeni korisnici koji koriste filtar korisnika ldap!)',
    'The default base DN used for searching for accounts.' => 'Zadana baza DN koja se koristi za traženje naloga.',
    'The default credentials password (used only with username above).' => 'The default credentials password (used only with username above).).',
    'The default credentials username. Some servers require that this be in DN form. This must be given in DN form if the LDAP server requires a DN to bind and binding should be possible with simple usernames.' => 'The default credentials username. Some servers require that this be in DN form. This must be given in DN form if the LDAP server requires a DN to bind and binding should be possible with simple usernames.',
    'User Filter' => 'Korisnički filter',
    'Username' => 'Korisničko ime',
    'Username Attribute' => 'Atribut korisničkog imena',
    'Ignored LDAP entries' => '',
    'One DN per line which should not be imported automatically.' => '',
];
