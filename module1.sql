CREATE DATABASE BaseAll;
USE BaseAll;

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@$$w0rd';

CREATE CERTIFICATE UserCert WITH SUBJECT = 'User Data Encryption';
CREATE SYMMETRIC KEY UserKey WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE UserCert;

CREATE TABLE Users (
	UserID INT IDENTITY(1,1) PRIMARY KEY,
	UserName NVARCHAR(10),
	EncryptedPassword VARBINARY(8000)
);

DECLARE @i INT = 1;
DECLARE @LoginName NVARCHAR(10);
DECLARE @Password NVARCHAR(10);

WHILE @i <= 9
BEGIN 
	SET @LoginName = CONCAT('d', @i);
	SET @Password = LEFT(CONVERT(VARCHAR(50), NEWID()), 8);

	EXEC('CREATE LOGIN ' + @LoginName + ' WITH PASSWORD = ''' + @Password + ''', CHECK_POLICY = OFF;');
	EXEC('CREATE DATABASE Base' + @i + ';');
	EXEC('ALTER AUTHORIZATION ON DATABASE::Base' + @i + ' TO ' + @LoginName + ';');

	EXEC('USE Base' + @i + '; CREATE USER ' + @LoginName + ' FOR LOGIN ' + @LoginName + ';');
	EXEC('USE Base' + @i + '; EXEC sp_addrolemember ''db_owner'', ''' + @LoginName + ''';');

	EXEC('DENY CREATE DATABASE TO [' + @LoginName + '];');
    EXEC('DENY ALTER ANY DATABASE TO [' + @LoginName + '];');

	OPEN SYMMETRIC KEY UserKey DECRYPTION BY CERTIFICATE UserCert;
	INSERT INTO Users VALUES
	(@LoginName, ENCRYPTBYKEY(KEY_GUID('UserKey'), @Password));
	CLOSE SYMMETRIC KEY UserKey;

	SET @i = @i + 1;
END;

OPEN SYMMETRIC KEY UserKey DECRYPTION BY CERTIFICATE UserCert;
SELECT UserID, UserName, CONVERT(NVARCHAR(10), DECRYPTBYKEY(EncryptedPassword)) AS DecryptedPassword
FROM Users;
CLOSE SYMMETRIC KEY UserKey;

BACKUP DATABASE BaseAll TO DISK = 'C:\Backups\BD.bak';

RESTORE DATABASE BaseAll FROM DISK = 'C:\Backups\BD.bak';