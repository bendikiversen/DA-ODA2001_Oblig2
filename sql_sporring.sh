#!/bin/bash
printf "Dette skriptet kan utføre følgende spørringer:\n \
1. filene til en bestemt bruker (oppgitt ved brukernavn)\n \
2. filstiene til en bestemt inode\n \
3. alle filene i en bestemt katalog\n \
4. vise sum av filer tilhørende brukerkontoer\n\n" /

read -p "Velg ønsket spørring: " valg
case $valg in
	1)
		read -p "Brukernavn: " brukernavn
    echo "SELECT filnavn FROM Filsystem NATURAL JOIN Inode WHERE brukernavn = '$brukernavn'; " | sqlite3 passwd.db
		;;
  2)
    read -p "Inode: " inode
    echo "SELECT filnavn FROM Filsystem NATURAL JOIN Inode WHERE inodenummer = '$inode';" | sqlite3 passwd.db
    ;;
  3)
    read -p "Katalog (fra /): " katalog
    echo "SELECT filnavn FROM Filsystem WHERE filnavn LIKE '$katalog%';" | sqlite3 passwd.db
    ;;
  4)
    echo "SELECT * from BrukerPlass;" | sqlite3 passwd.db | column -ts'${|}'
    ;;
esac
