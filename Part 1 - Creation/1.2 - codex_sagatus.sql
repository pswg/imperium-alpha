-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.

ALTER PROCEDURE [Sacrum].[CodexSagatus]
AS
BEGIN
  PRINT "/*******************************************************************************";
  PRINT "* VERSU I: Rhapsodia Vacui";
  PRINT "* The Great Sa, the creator and the destroyer of all things, sleeps in the";
  PRINT "* quiet place outside of the world—in the void between worlds—brooding and ";
  PRINT "* eternal.";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "USE [master];";
  PRINT "GO";
  PRINT "/*******************************************************************************";
  PRINT "* VERSU II: Scopa Fati";
  PRINT "* The Great Sa, desiring to create for emself the world, swept eir hands";
  PRINT "* through the void and created a hollow place where once there was only void.";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "EXEC [msdb].[dbo].[sp_delete_database_backuphistory] [Alpha];";
  PRINT "IF EXISTS( SELECT * FROM [master].[sys].[databases] WHERE [name] = 'Alpha' )";
  PRINT "BEGIN";
  PRINT "ALTER DATABASE [Alpha] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;";
  PRINT "DROP DATABASE [Alpha];";
  PRINT "END";
  PRINT "GO";
  PRINT "/*******************************************************************************";
  PRINT "* VERSU III: Creatio Mundi";
  PRINT "* In the space that had been made in the Void, the Great Sa formed the world,";
  PRINT "* Alpha.";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "CREATE DATABASE [Alpha] CONTAINMENT = PARTIAL;";
  PRINT "GO";
  PRINT "/*******************************************************************************";
  PRINT "* VERSU IV: Descursus Saii";
  PRINT "* The Great Sa descended to Alpha so that e may inspect the world e had";
  PRINT "* created.";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "USE [Alpha];";
  PRINT "GO";
  PRINT "/*******************************************************************************";
  PRINT "* VERSU V: Sacrum Axis Mundi";
  PRINT "* Upon the rock in the center of the world, the Great Sa founded eir temple, ";
  PRINT "* the Sacrum, to hold sacred relics and rituals.";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "CREATE SCHEMA [Sacrum];";
  PRINT "GO";
  PRINT "/*******************************************************************************";
  PRINT "* VERSU VI: Vox Sacri";
  PRINT "* In the innermost sanctum of the Sacrum, The Great Sa placed a stone, called";
  PRINT "* the Echo, and placed an enchantment it so that if anyone spoke into the Echo,";
  PRINT "* it would echo with eir voice long afterwards and even the Great Sa would";
  PRINT "* hear.";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "CREATE TABLE [Sacrum].[Echo](";
  PRINT "[Vox] nvarchar( 1000 ) NOT NULL ,";
  PRINT "[Vocator] sysname NOT NULL ,";
  PRINT "[FatumHorae] datetime NOT NULL );";
  PRINT "GO";
  PRINT "/*******************************************************************************";
  PRINT "* VERSU VII: Comprimere Echui";
  PRINT "* However, should anyone call for the Echo to be silent before the voice of";
  PRINT "* the Echo had been heard by the Great Sa, so it would be silent once more.";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "CREATE PROCEDURE [Sacrum].[Comprime]";
  PRINT "WITH EXECUTE AS OWNER";
  PRINT "AS";
  PRINT "BEGIN";
  PRINT "DECLARE @d datetime;";
  PRINT "SELECT @d = [FatumHorae] FROM [Sacrum].[Echo];";
  PRINT "IF @d IS NULL";
  PRINT "PRINT 'Fear not, mortal! The Apocalyse is not near!';";
  PRINT "ELSE IF @d < GETUTCDATE()";
  PRINT "BEGIN";
  PRINT "TRUNCATE TABLE [Sacrum].[Echo];";
  PRINT "PRINT 'The Apocalypse has been averted!';";
  PRINT "END";
  PRINT "ELSE";
  PRINT "PRINT 'It is too late, mortal! All is lost!';";
  PRINT "END";
  PRINT "GO";
  PRINT "/*******************************************************************************";
  PRINT "* VERSU VIII: Prophetia Apocalypsi";
  PRINT "* The Great Sa made a vow, saying, ""Should anyone speak into the Echo of the";
  PRINT "* Sacrum and the Echo yet ring with eir voice for a 2 full days, then I shall";
  PRINT "* return to destroy the world that I had created.""";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "CREATE PROCEDURE [Sacrum].[Loquere]";
  PRINT "@Vox nvarchar( 1000 )";
  PRINT "WITH EXECUTE AS OWNER";
  PRINT "AS";
  PRINT "BEGIN";
  PRINT "IF EXISTS( SELECT * FROM [Sacrum].[Echo] )";
  PRINT "PRINT 'Hasten not the Apocalypse, mortal! It is already near!';";
  PRINT "IF @Vox IS NULL";
  PRINT "PRINT 'These words are hollow, mortal!';";
  PRINT "ELSE";
  PRINT "BEGIN";
  PRINT "DECLARE @d datetime;";
  PRINT "SET @d = DATEADD( D , 2 , GETUTCDATE() );";
  PRINT "INSERT [Sacrum].[Echo]( [Vox] , [Vocator] , [FatumHorae] )";
  PRINT "VALUES( @Vox , CURRENT_USER , @d );";
  PRINT "PRINT 'Prepare yourself, mortal! The Apocalypse is near!';";
  PRINT "END";
  PRINT "END";
  PRINT "GO";
  PRINT "/*******************************************************************************";
  PRINT "* VERSU IX: Codex Sagatus";
  PRINT "* The Great Sa plucked a scrap of fabric from eir cloak and created from it a";
  PRINT "* book, the Codex Sagatus, wherein the deeds and sayings of the Great Sa would";
  PRINT "* be written, and placed it within the Sacrum.";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "CREATE PROCEDURE [Sacrum].[CodexSagatus]";
  PRINT "AS";
  PRINT "BEGIN";
  PRINT "PRINT '***PLACEHOLDER***';";
  PRINT "END";
  PRINT "GO";
  PRINT "/*******************************************************************************";
  PRINT "* VERSU X: Copia Sacri";
  PRINT "* The Great Sa declared that all would be welcome within the Sacrum and to read";
  PRINT "* from the Codex Sagatus and listen to the voice of the Echo, but only high";
  PRINT "* priests, or Sacerdos, would be trusted with the rituals of the Sacrum.";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "GRANT EXECUTE ON OBJECT::[Sacrum].[CodexSagatus] TO PUBLIC;";
  PRINT "GRANT SELECT , REFERENCES ON OBJECT::[Sacrum].[Echo] TO PUBLIC;";
  PRINT "CREATE ROLE [Sacerdos];";
  PRINT "GRANT EXECUTE , VIEW DEFINITION ON OBJECT::[Sacrum].[Loquere] TO [Sacerdos];";
  PRINT "GRANT EXECUTE , VIEW DEFINITION ON OBJECT::[Sacrum].[Comprime] TO [Sacerdos];";
  PRINT "GO";
  PRINT "/*******************************************************************************";
  PRINT "* VERSU XI: Archon Nascitur";
  PRINT "* The Great Sa called forth from eir own mind the god-king Archon and granted";
  PRINT "* em dominion over all of the lands of Alpha, save only the Sacrum, which would";
  PRINT "* be immovable and immutable until the end of the world.";
  PRINT "*******************************************************************************/";
  PRINT "GO";
  PRINT "CREATE USER [Archon] WITHOUT LOGIN;";
  PRINT "GRANT CONTROL TO [Archon] WITH GRANT OPTION;";
  PRINT "DENY CONTROL ON SCHEMA::[Sacrum] TO [Archon];";
  PRINT "GO";
END
