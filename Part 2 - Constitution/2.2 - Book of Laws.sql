-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

/*******************************************************************************
 * IMPERIAL LAW 2 : The Book of Laws
 * The Imperitor of the Imperium, Archon, does hereby proclaim that all subjects
 * of The Imperium shall act in accordance with the laws written in the Book of
 * Laws.
*******************************************************************************/

/*******************************************************************************
 * 2.1 : Definition of Laws
 * Each [law][1] recorded in the Book of Laws shall include a unique numeric
 * identifier (ID), a name, a preamble, the date and time that the law was
 * enacted, and the identity of the individual that enacted the law, and one or
 * more [clauses][2].
 *
 *   [1]: OBJECT::[Imperium].[Laws]
 *   [2]: OBJECT::[Imperium].[Clauses]
*******************************************************************************/
GO
CREATE TABLE [Imperium].[Laws](
  [Id] bigint NOT NULL
              IDENTITY( 1 , 1 )
              PRIMARY KEY ,
  [Name] sysname NOT NULL ,
  [Preamble] nvarchar(4000) NOT NULL ,
  [EnactedOn] datetime NOT NULL ,
  [EnactedBy] int NOT NULL );
GO

/*******************************************************************************
 * 2.2 : Definition of Clause Tables
 * Each [clause][1] written in [Book of Laws][2] shall include the ID of the law
 * of which the clause is a part, the number of the clause within the law of
 * which the clause is a part, a name, a statement writen in English, and a
 * statement written in SQL. The combination of law ID and clause number shall
 * be unique within the Book of Laws.
 *
 *   [1]: OBJECT::[Imperium].[Clauses]
 *   [2]: OBJECT::[Imperium].[Laws]
*******************************************************************************/
GO
CREATE TABLE [Imperium].[Clauses](
  [LawId] bigint NOT NULL ,
  [ClauseNumber] int NOT NULL ,
  [Name] sysname NULL ,
  [English] nvarchar(4000) NOT NULL ,
  [Statement] nvarchar(4000) NOT NULL ,
  PRIMARY KEY ( [LawId] , [ClauseNumber] ) ,
  FOREIGN KEY ( [LawId] ) REFERENCES [Imperium].[Laws] ( [Id] ));
GO

/*******************************************************************************
 * 2.3 : Definition of Clauses
 * A [clause table][1] is a collection of items which shall consist of a clause
 * number, unique within the clause table, a name, a statement writen in
 * English, and a statement writen in SQL.
 *
 *   [1]: TYPE::[Imperium].[ClauseTable]
*******************************************************************************/
GO
CREATE TYPE [Imperium].[ClauseTable] AS TABLE(
  [ClauseNumber] int NOT NULL
                     IDENTITY( 1 , 1 )
                     PRIMARY KEY ,
  [Name] sysname NULL ,
  [English] nvarchar(4000) NOT NULL ,
  [Statement] nvarchar(4000) NOT NULL );
GO

/*******************************************************************************
 * 2.4 : Book of History
 * Each line in the [Book of History][1] shall include a unique numeric
 * identifier representing that line, the type of change event that the line
 * records, the type of object that the line regards, the name of the object
 * that the line regards, the region of the world where the object resides
 * (schema), the ID of the associated [law][2], and the number of the associated
 * [clause][3]. The law ID and clause number of each line recorded in the Book
 * of History must have a corresponding clause recorded in the Book of Laws.
 *
 *   [1]: OBJECT::[Imperium].[History]
 *   [2]: OBJECT::[Imperium].[Laws]
 *   [3]: OBJECT::[Imperium].[Clauses]
*******************************************************************************/
GO
CREATE TABLE [Imperium].[History](
  [Id] bigint NOT NULL
              IDENTITY( 1 , 1 )
              PRIMARY KEY ,
  [EventType] sysname NOT NULL ,
  [ObjectType] sysname NOT NULL ,
  [ObjectName] sysname NOT NULL ,
  [SchemaName] sysname NOT NULL ,
  [LawId] bigint NOT NULL ,
  [ClauseNumber] int NOT NULL ,
  FOREIGN KEY ( [LawId] , [ClauseNumber] )
  REFERENCES [Imperium].[Clauses] ( [LawId] , [ClauseNumber] ));
GO

/*******************************************************************************
 * 2.5 : The Enactment Stack
 * There shall be a [enactment stack][1] which indicates the law and clause
 * currently being enacted. Each item in the enactment stack shall consist of a
 * unique order number, a [law][2] ID, and a [clause][3] number. The law ID and
 * clause number of each item in the enactment stack must have a corresponding
 * clause recorded in the Book of Laws.
 *
 *   [1]: OBJECT::[Imperium].[EnactmentStack]
 *   [2]: OBJECT::[Imperium].[Laws]
 *   [3]: OBJECT::[Imperium].[Clauses]
*******************************************************************************/
GO
CREATE TABLE [Imperium].[EnactmentStack](
  [Order] tinyint NOT NULL
                  PRIMARY KEY ,
  [LawId] bigint NOT NULL ,
  [ClauseNumber] int NOT NULL ,
  FOREIGN KEY ( [LawId] , [ClauseNumber] )
  REFERENCES [Imperium].[Clauses] ( [LawId] , [ClauseNumber] ));
GO

/*******************************************************************************
 * 2.6 : Pushing to the Enactment Stack
 * To [push an item to the enactment stack][1] is to add a new item to the
 * [enactment stack][2] containing a specified law ID and clause number and an
 * order number equal to one more than the greatest order number currently on
 * the stack.
 *
 *   [1]: OBJECT::[Imperium].[PushEnactment]
 *   [2]: OBJECT::[Imperium].[EnactmentStack]
*******************************************************************************/
GO
CREATE PROCEDURE [Imperium].[PushEnactment]
  @lawId bigint ,
  @clauseNumber int
  WITH EXECUTE AS CALLER
AS
BEGIN
  INSERT [Imperium].[EnactmentStack](
    [Order] ,
    [LawId] ,
    [ClauseNumber] )
  SELECT
    ISNULL( MAX( [Order] ) + 1 , 0 ) ,
    @lawId ,
    @clauseNumber
  FROM [Imperium].[EnactmentStack];
END
GO

/*******************************************************************************
 * 2.7 : Popping from the Enactment Stack
 * To [pop an item from the enactment stack][1] is to remove the item from the
 * [enactment stack][2] which has the greatest order number, if one exists.
 *
 *   [1]: OBJECT::[Imperium].[PopEnactment]
 *   [2]: OBJECT::[Imperium].[EnactmentStack]
*******************************************************************************/
GO
CREATE PROCEDURE [Imperium].[PopEnactment]
  WITH EXECUTE AS CALLER
AS
BEGIN
  DELETE [Imperium].[EnactmentStack]
  WHERE [Order] = ( SELECT MAX([Order]) FROM [Imperium].[EnactmentStack] );
END
GO

/*******************************************************************************
 * 2.8 : Recording History
 * When an object within the world of Alpha is changed, if the [enactment
 * stack][1] is not empty, the [law][2] ID and [clause][3] number of item in the
 * enactment stack with the greatest order number, the type of change event that
 * occurred, the type of the object that was changed, the name of the object
 * that was changed, and the region of the world where the object resides
 * (schema) shall be [recorded][4] in the [Book of History][5].
 *
 *   [1]: OBJECT::[Imperium].[EnactmentStack]
 *   [2]: OBJECT::[Imperium].[Laws]
 *   [3]: OBJECT::[Imperium].[Clauses]
 *   [4]: TRIGGER::[RecordHistory]
 *   [5]: OBJECT::[Imperium].[History]
*******************************************************************************/
GO
CREATE TRIGGER [RecordHistory]
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
  SET QUOTED_IDENTIFIER ON;
  DECLARE @d XML = EVENTDATA();
  DECLARE @eventType sysname =
            @d.value( '(/EVENT_INSTANCE/EventType)[1]' , 'sysname' ) ,
          @objType sysname =
            @d.value( '(/EVENT_INSTANCE/ObjectType)[1]' , 'sysname' ) ,
          @schName sysname =
            @d.value( '(/EVENT_INSTANCE/SchemaName)[1]' , 'sysname' ) ,
          @objName sysname =
            @d.value( '(/EVENT_INSTANCE/ObjectName)[1]' , 'sysname' ) ,
          @lawId bigint ,
          @clauseNumber int;
  SET @schName = ISNULL( @schName , '' );
  SELECT TOP 1
      @lawId = [LawId] ,
      @clauseNumber = [ClauseNumber]
    FROM [Imperium].[EnactmentStack]
    ORDER BY [Order];
  IF( @lawId IS NOT NULL AND
      NOT EXISTS( SELECT [Id]
                    FROM [Imperium].[History]
                    WHERE [EventType] = @eventType AND
                          [ObjectType] = @objType AND
                          [ObjectName] = @objName AND
                          [SchemaName] = @schName AND
                          [LawId] = @lawId AND
                          [ClauseNumber] = @clauseNumber ))
    INSERT [Imperium].[History](
        [EventType] ,
        [ObjectType] ,
        [ObjectName] ,
        [SchemaName] ,
        [LawId] ,
        [ClauseNumber] )
      VALUES(
        @eventType ,
        @objType ,
        @objName ,
        @schName ,
        @lawId ,
        @clauseNumber );
END
GO

/*******************************************************************************
 * 2.9 : Enactment of Laws
 * To [enact a law][1] with a specified name and consisting of clauses as
 * described in a specified [clause table is][2] to execute the following
 * procedure:
 *
 *   1. enscribe a new law into the [Book of Laws][3] with the specified name
 *      and preamble, including the date and time that the law was enacted and
 *      the identity of the enactor
 *   2. for each item in a specified clause table
 *     1. enscribe the item's clause number, normalized to start at one (1) and
 *        increase by one (1) with each subsequent clause, English statement,
 *        and SQL statement as [clauses][4] under the new law in the Book of
 *        Laws.
 *     2. push the new law's ID and the new clause's number to the enactment
 *        stack
 *     3. execute the item's SQL statement
 *     4. pop an item from the enactment stack
 *
 * If the clause table is empty, or if the execution of the SQL statement of any
 * clause in the clause table results in an error being raised, the new law and
 * all its clauses will be stricken from the Book of Laws, and any changes made
 * to the world as a result of the enactment of the law shall be undone to the
 * extent that undoing those changes is possible within the enactment procedure.
 *
 *   [1]: OBJECT::[Imperium].[Enact]
 *   [2]: TYPE::[Imperium].[ClauseTable]
 *   [3]: OBJECT::[Imperium].[Laws]
 *   [4]: OBJECT::[Imperium].[Clauses]
*******************************************************************************/
GO
CREATE PROCEDURE [Imperium].[Enact]
  @name sysname ,
  @preamble nvarchar(4000) ,
  @clauses [Imperium].[ClauseTable] READONLY ,
  @lawId bigint = NULL OUTPUT ,
  @errorMessage nvarchar(4000) = NULL OUTPUT
  WITH EXECUTE AS CALLER
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
  DECLARE @id int ,
          @xc int = @@TRANCOUNT ,
          @sp nvarchar(100) = 'Enactment_' + CAST( NEWID() AS nvarchar(36) );
  IF @xc = 0
    BEGIN TRANSACTION [Enact] WITH MARK 'Enact';
  ELSE
    SAVE TRANSACTION @sp;
  DECLARE @results TABLE( [Id] int NOT NULL );
  INSERT [Imperium].[Laws]( [Name] , [Preamble] , [EnactedOn] , [EnactedBy] )
    OUTPUT [inserted].[Id] INTO @results
    VALUES ( @name , @preamble , GETUTCDATE() , USER_ID() );
  SELECT @id = [Id] FROM @results;

  DECLARE @cTitle sysname ,
          @english nvarchar(4000) ,
          @statement nvarchar(4000) ,
          @clauseNum int = 0;
  DECLARE [ClauseCursor] CURSOR LOCAL FAST_FORWARD
    FOR SELECT [Name] , [English] , [Statement]
          FROM @clauses
          ORDER BY [ClauseNumber];
  OPEN [ClauseCursor];
  FETCH NEXT FROM [ClauseCursor] INTO @cTitle , @english , @statement;
  WHILE( @@FETCH_STATUS = 0 )
    BEGIN
      SET @clauseNum += 1;
      BEGIN TRY
        INSERT [Imperium].[Clauses](
            [LawId] ,
            [ClauseNumber] ,
            [Name] ,
            [English] ,
            [Statement] )
          VALUES( @id , @clauseNum , @cTitle , @english , @statement );
        IF @cTitle IS NULL
          SET @cTitle =
            CAST( @id AS nvarchar(30) ) + '.' +
            CAST( @clauseNum AS nvarchar(30) );
        EXEC [Imperium].[PushEnactment] @id , @clauseNum;
        EXEC ( @statement );
        EXEC [Imperium].[PopEnactment];
      END TRY
      BEGIN CATCH
        DECLARE @msg nvarchar(1000);
        EXEC [sys].[xp_sprintf]
          @msg OUTPUT ,
          'Error enacting law ''%s'', clause ''%s'' (%s.%s).' ,
          @name , @cTitle , @id , @clauseNum;
        PRINT( @msg );
        IF @xc = 0
          ROLLBACK TRANSACTION;
        ELSE
          ROLLBACK TRANSACTION @sp;
        SET @errorMessage = ERROR_MESSAGE();
        THROW;
      END CATCH
      FETCH NEXT FROM [ClauseCursor] INTO @cTitle , @english , @statement;
    END

  CLOSE [ClauseCursor];
  DEALLOCATE [ClauseCursor];

  IF @xc = 0
    COMMIT TRANSACTION [Enact];
  SET @lawId = @id;

  SET NOCOUNT OFF;
  RETURN 0;
END
GO

/*******************************************************************************
 * 2.10 : Recitation of Laws
 * To [recite][1] from the [Book of Laws][2] is to read all the ID and name a
 * specified law, followed by the number, name, English statement, and SQL
 * statement of each of its [clauses][3] or a specified clause.
 *
 *   [1]: OBJECT::[Imperium].[Recite]
 *   [2]: OBJECT::[Imperium].[Laws]
 *   [3]: OBJECT::[Imperium].[Clauses]
*******************************************************************************/
GO
CREATE PROCEDURE [Imperium].[Recite]
  @law sql_variant ,
  @clauseNum int = NULL
  WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @lawId nvarchar(30) ,
          @lawName sysname ,
          @enactedOn nvarchar(30) ,
          @enactedBy sysname ,
          @clauseName sysname ,
          @hr nvarchar(78) = REPLACE( SPACE(78) , ' ' , '*' ) ,
          @english nvarchar(4000) ,
          @statement nvarchar(4000);
  IF @law IS NULL
    RETURN;
  SELECT TOP (1)
      @lawId = CAST( [Id] AS nvarchar(30)) ,
      @lawName = [Name] ,
      @enactedOn = CONVERT( nvarchar(30) , [EnactedOn] , 20 ) ,
      @enactedBy = USER_NAME ( [EnactedBy] )
    FROM [Imperium].[Laws]
    WHERE
      [Id] = CASE
          WHEN SQL_VARIANT_PROPERTY( @law , 'BaseType' )
               IN( 'smallint' , 'tinyint' , 'bigint' , 'int' )
          THEN CAST( @law AS bigint )
          ELSE [Id]
        END AND
      [Name] = CASE
          WHEN SQL_VARIANT_PROPERTY( @law , 'BaseType' )
               IN( 'varchar', 'nvarchar' )
          THEN CAST( @law AS sysname )
          ELSE [Name]
        END
    ORDER BY [Id] ASC;

  PRINT '-- # IMPERIAL LAW ' + @lawId;
  PRINT '-- ' + @lawName;
  PRINT '-- enacted on ' + @enactedOn;
  PRINT '--         by ' + @enactedBy;
  PRINT '';

  DECLARE [ClauseCursor] CURSOR
    FOR SELECT
            ISNULL( NULLIF( [Name] , '' ) , '(unnamed clause)' ) ,
            CAST( [ClauseNumber] AS nvarchar(30)),
            LTRIM( RTRIM( [English] )),
            LTRIM( RTRIM( [Statement] ))
          FROM [Imperium].[Clauses]
          WHERE [LawId] = @lawId AND
                [ClauseNumber] = ISNULL( @clauseNum , [ClauseNumber] )
          ORDER BY [ClauseNumber];
  OPEN [ClauseCursor];
  FETCH NEXT FROM [ClauseCursor]
    INTO @clauseName , @clauseNum , @english , @statement;
  WHILE( @@FETCH_STATUS = 0 )
    BEGIN
      DECLARE @cnum nvarchar( 30 ) = CAST( @clauseNum AS nvarchar(30) );
      PRINT '/*' + @hr;
      PRINT ' * ' + @lawId + '.' + @cnum + ': ' + @clauseName;
      DECLARE @n int = CHARINDEX( CHAR(13) + CHAR(10) , @english );
      WHILE( @n > 0 )
        BEGIN
          PRINT ' * ' + SUBSTRING( @english , 0, @n + 2 );
          SET @english = SUBSTRING( @english , @n + 2, LEN( @english ));
          SET @n = CHARINDEX( CHAR(13) + CHAR(10) , @english );
        END
      PRINT ' * ' + @english;
      PRINT @hr + '*/';

      PRINT 'GO';
      PRINT @statement;
      PRINT 'GO';
      PRINT '';

      FETCH NEXT FROM [ClauseCursor]
        INTO @clauseName , @clauseNum , @english , @statement;
    END
  CLOSE [ClauseCursor];
  DEALLOCATE [ClauseCursor];
END
GO

-- INSERT LAWS 1 & 2 INTO THE BOOK OF LAWS
SET QUOTED_IDENTIFIER OFF;
INSERT [Imperium].[Laws]
    ( [Name] , [Preamble] , [EnactedOn] , [EnactedBy] )
  VALUES
    ( "Foundation of the Imperium" ,
"The god-king, Archon, does hereby proclaim, the founding of a great nation,
 * called The Imperium." ,
      GETUTCDATE() , USER_ID() );
INSERT [Imperium].[Clauses]
    ( [LawId] , [ClauseNumber] , [Name] , [English] , [Statement] )
  VALUES
    ( 1 , 1 ,
      "Foundation of The Imperium" ,
"There shall be a great nation, called [The Imperium][1].

  [1]: SCHEMA::[Imperium]" ,
"CREATE SCHEMA [Imperium];" ) ,
    ( 1 , 2 ,
      "Office of the Imperitor" ,
"Complete governing authority over [The Imperium][1] shall be held by [The
 Imperitor][2].

  [1]: SCHEMA::[Imperium]
  [2]: ROLE::[Imperitor]" ,
"CREATE ROLE [Imperitor];
GRANT CONTROL ON SCHEMA::[Imperium] TO [Imperitor] WITH GRANT OPTION;" ) ,
    ( 1 , 3 ,
      "Assumption of Archon" ,
"The first [Imperitor][1] shall be the god-king, [Archon][2].

  [1]: ROLE::[Imperitor]
  [2]: USER::[Archon]" ,
"ALTER ROLE [Imperitor] ADD MEMBER [Archon];" );
INSERT [Imperium].[Laws]
    ( [Name] , [Preamble] , [EnactedOn] , [EnactedBy] )
  VALUES
    ( "The Book of Laws" ,
"The Imperitor of the Imperium, Archon, does hereby proclaim that all subjects
of The Imperium shall act in accordance with the laws written in the Book of
Laws." ,
      GETUTCDATE() , USER_ID() );
INSERT [Imperium].[Clauses]
    ( [LawId] , [ClauseNumber] , [Name] , [English] , [Statement] )
  VALUES
    ( 2 , 1 ,
      "Definition of Laws" ,
"Each [law][1] recorded in the Book of Laws shall include a unique numeric
identifier (ID), a name, a preamble, the date and time that the law was
enacted, and the identity of the individual that enacted the law, and one or
more [clauses][2].

  [1]: OBJECT::[Imperium].[Laws]
  [1]: OBJECT::[Imperium].[Clauses]" ,
"CREATE TABLE [Imperium].[Laws](
  [Id] bigint NOT NULL
              IDENTITY( 1 , 1 )
              PRIMARY KEY ,
  [Name] sysname NOT NULL ,
  [Preamble] nvarchar(4000) NOT NULL ,
  [EnactedOn] datetime NOT NULL ,
  [EnactedBy] int NOT NULL );" ) ,
    ( 2 , 2 ,
      "Definition of Clause Tables" ,
"Each [clause][1] written in [Book of Laws][2] shall include the ID of the law
of which the clause is a part, the number of the clause within the law of
which the clause is a part, a name, a statement writen in English, and a
statement written in SQL. The combination of law ID and clause number shall
be unique within the Book of Laws.

  [1]: OBJECT::[Imperium].[Clauses]
  [2]: OBJECT::[Imperium].[Laws]",
"CREATE TABLE [Imperium].[Clauses](
  [LawId] bigint NOT NULL ,
  [ClauseNumber] int NOT NULL ,
  [Name] sysname NULL ,
  [English] nvarchar(4000) NOT NULL ,
  [Statement] nvarchar(4000) NOT NULL ,
  PRIMARY KEY ( [LawId] , [ClauseNumber] ) ,
  FOREIGN KEY ( [LawId] ) REFERENCES [Imperium].[Laws] ( [Id] ));" ) ,
    ( 2 , 3 ,
      "Definition of Clauses" ,
"A [clause table][1] is a collection of items which shall consist of a clause
number, unique within the clause table, a name, a statement writen in
English, and a statement writen in SQL.

  [1]: TYPE::[Imperium].[ClauseTable]" ,
"CREATE TYPE [Imperium].[ClauseTable] AS TABLE(
  [ClauseNumber] int NOT NULL
                     IDENTITY( 1 , 1 )
                     PRIMARY KEY ,
  [Name] sysname NULL ,
  [English] nvarchar(4000) NOT NULL ,
  [Statement] nvarchar(4000) NOT NULL );" ) ,
    ( 2 , 4 ,
      "Book of History" ,
"Each line in the [Book of History][1] shall include a unique numeric
identifier representing that line, the type of change event that the line
records, the type of object that the line regards, the name of the object
that the line regards, the region of the world where the object resides
(schema), the ID of the associated [law][2], and the number of the associated
[clause][3]. The law ID and clause number of each line recorded in the Book
of History must have a corresponding clause recorded in the Book of Laws.

  [1]: OBJECT::[Imperium].[History]
  [2]: OBJECT::[Imperium].[Laws]
  [3]: OBJECT::[Imperium].[Clauses]" ,
"CREATE TABLE [Imperium].[History](
  [Id] bigint NOT NULL
              IDENTITY( 1 , 1 )
              PRIMARY KEY ,
  [EventType] sysname NOT NULL ,
  [ObjectType] sysname NOT NULL ,
  [ObjectName] sysname NOT NULL ,
  [SchemaName] sysname NOT NULL ,
  [LawId] bigint NOT NULL ,
  [ClauseNumber] int NOT NULL ,
  FOREIGN KEY ( [LawId] , [ClauseNumber] )
  REFERENCES [Imperium].[Clauses] ( [LawId] , [ClauseNumber] ));" ) ,
    ( 2 , 5 ,
      "The Enactment Stack" ,
"There shall be a [enactment stack][1] which indicates the law and clause
currently being enacted. Each item in the enactment stack shall consist of a
unique order number, a [law][2] ID, and a [clause][3] number. The law ID and
clause number of each item in the enactment stack must have a corresponding
clause recorded in the Book of Laws.

  [1]: OBJECT::[Imperium].[EnactmentStack]
  [2]: OBJECT::[Imperium].[Laws]
  [3]: OBJECT::[Imperium].[Clauses]" ,
"CREATE TABLE [Imperium].[EnactmentStack](
  [Order] tinyint NOT NULL
                  PRIMARY KEY ,
  [LawId] bigint NOT NULL ,
  [ClauseNumber] int NOT NULL ,
  FOREIGN KEY ( [LawId] , [ClauseNumber] )
  REFERENCES [Imperium].[Clauses] ( [LawId] , [ClauseNumber] ));" ) ,
    ( 2 , 6 ,
      "Pushing to the Enactment Stack" ,
"To [push an item to the enactment stack][1] is to add a new item to the
[enactment stack][2] containing a specified law ID and clause number and an
order number equal to one more than the greatest order number currently on
the stack.

  [1]: OBJECT::[Imperium].[PushEnactment]
  [2]: OBJECT::[Imperium].[EnactmentStack]" ,
"CREATE PROCEDURE [Imperium].[PushEnactment]
  @lawId bigint ,
  @clauseNumber int
  WITH EXECUTE AS CALLER
AS
BEGIN
  INSERT [Imperium].[EnactmentStack](
    [Order] ,
    [LawId] ,
    [ClauseNumber] )
  SELECT
    ISNULL( MAX( [Order] ) + 1 , 0 ) ,
    @lawId ,
    @clauseNumber
  FROM [Imperium].[EnactmentStack];
END" ) ,
    ( 2 , 7 ,
      "Popping from the Enactment Stack" ,
"To [pop an item from the enactment stack][1] is to remove the item from the
[enactment stack][2] which has the greatest order number, if one exists.

  [1]: OBJECT::[Imperium].[PopEnactment]
  [2]: OBJECT::[Imperium].[EnactmentStack]" ,
"CREATE PROCEDURE [Imperium].[PopEnactment]
  WITH EXECUTE AS CALLER
AS
BEGIN
  DELETE [Imperium].[EnactmentStack]
  WHERE [Order] = ( SELECT MAX([Order]) FROM [Imperium].[EnactmentStack] );
END" ) ,
    ( 2 , 8 ,
      "Recording History" ,
"When an object within the world of Alpha is changed, if the [enactment
stack][1] is not empty, the [law][2] ID and [clause][3] number of item in the
enactment stack with the greatest order number, the type of change event that
occurred, the type of the object that was changed, the name of the object
that was changed, and the region of the world where the object resides
(schema) shall be [recorded][4] in the [Book of History][5].

  [1]: OBJECT::[Imperium].[EnactmentStack]
  [2]: OBJECT::[Imperium].[Laws]
  [3]: OBJECT::[Imperium].[Clauses]
  [4]: TRIGGER::[RecordHistory]
  [5]: OBJECT::[Imperium].[History]" ,
"CREATE TRIGGER [RecordHistory]
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
  SET QUOTED_IDENTIFIER ON;
  DECLARE @d XML = EVENTDATA();
  DECLARE @eventType sysname =
            @d.value( '(/EVENT_INSTANCE/EventType)[1]' , 'sysname' ) ,
          @objType sysname =
            @d.value( '(/EVENT_INSTANCE/ObjectType)[1]' , 'sysname' ) ,
          @schName sysname =
            @d.value( '(/EVENT_INSTANCE/SchemaName)[1]' , 'sysname' ) ,
          @objName sysname =
            @d.value( '(/EVENT_INSTANCE/ObjectName)[1]' , 'sysname' ) ,
          @lawId bigint ,
          @clauseNumber int;
  SET @schName = ISNULL( @schName , '' );
  SELECT TOP 1
      @lawId = [LawId] ,
      @clauseNumber = [ClauseNumber]
    FROM [Imperium].[EnactmentStack]
    ORDER BY [Order];
  IF( @lawId IS NOT NULL AND
      NOT EXISTS( SELECT [Id]
                    FROM [Imperium].[History]
                    WHERE [EventType] = @eventType AND
                          [ObjectType] = @objType AND
                          [ObjectName] = @objName AND
                          [SchemaName] = @schName AND
                          [LawId] = @lawId AND
                          [ClauseNumber] = @clauseNumber ))
    INSERT [Imperium].[History](
        [EventType] ,
        [ObjectType] ,
        [ObjectName] ,
        [SchemaName] ,
        [LawId] ,
        [ClauseNumber] )
      VALUES(
        @eventType ,
        @objType ,
        @objName ,
        @schName ,
        @lawId ,
        @clauseNumber );
END" ) ,
    ( 2 , 9 ,
      "Enactment of Laws" ,
"To [enact a law][1] with a specified name and consisting of clauses as
described in a specified [clause table is][2] to execute the following
procedure:

  1. enscribe a new law into the [Book of Laws][3] with the specified name
     and preamble, including the date and time that the law was enacted and
     the identity of the enactor
  2. for each item in a specified clause table
    1. enscribe the item's clause number, normalized to start at one (1) and
       increase by one (1) with each subsequent clause, English statement,
       and SQL statement as [clauses][4] under the new law in the Book of
       Laws.
    2. push the new law's ID and the new clause's number to the enactment
       stack
    3. execute the item's SQL statement
    4. pop an item from the enactment stack

If the clause table is empty, or if the execution of the SQL statement of any
clause in the clause table results in an error being raised, the new law and
all its clauses will be stricken from the Book of Laws, and any changes made
to the world as a result of the enactment of the law shall be undone to the
extent that undoing those changes is possible within the enactment procedure.

  [1]: OBJECT::[Imperium].[Enact]
  [2]: TYPE::[Imperium].[ClauseTable]
  [3]: OBJECT::[Imperium].[Laws]
  [4]: OBJECT::[Imperium].[Clauses]" ,
"CREATE PROCEDURE [Imperium].[Enact]
  @name sysname ,
  @preamble nvarchar(4000) ,
  @clauses [Imperium].[ClauseTable] READONLY ,
  @lawId bigint = NULL OUTPUT ,
  @errorMessage nvarchar(4000) = NULL OUTPUT
  WITH EXECUTE AS CALLER
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
  DECLARE @id int ,
          @xc int = @@TRANCOUNT ,
          @sp nvarchar(100) = 'Enactment_' + CAST( NEWID() AS nvarchar(36) );
  IF @xc = 0
    BEGIN TRANSACTION [Enact] WITH MARK 'Enact';
  ELSE
    SAVE TRANSACTION @sp;
  DECLARE @results TABLE( [Id] int NOT NULL );
  INSERT [Imperium].[Laws]( [Name] , [Preamble] , [EnactedOn] , [EnactedBy] )
    OUTPUT [inserted].[Id] INTO @results
    VALUES ( @name , @preamble , GETUTCDATE() , USER_ID() );
  SELECT @id = [Id] FROM @results;

  DECLARE @cTitle sysname ,
          @english nvarchar(4000) ,
          @statement nvarchar(4000) ,
          @clauseNum int = 0;
  DECLARE [ClauseCursor] CURSOR LOCAL FAST_FORWARD
    FOR SELECT [Name] , [English] , [Statement]
          FROM @clauses
          ORDER BY [ClauseNumber];
  OPEN [ClauseCursor];
  FETCH NEXT FROM [ClauseCursor] INTO @cTitle , @english , @statement;
  WHILE( @@FETCH_STATUS = 0 )
    BEGIN
      SET @clauseNum += 1;
      BEGIN TRY
        INSERT [Imperium].[Clauses](
            [LawId] ,
            [ClauseNumber] ,
            [Name] ,
            [English] ,
            [Statement] )
          VALUES( @id , @clauseNum , @cTitle , @english , @statement );
        IF @cTitle IS NULL
          SET @cTitle =
            CAST( @id AS nvarchar(30) ) + '.' +
            CAST( @clauseNum AS nvarchar(30) );
        EXEC [Imperium].[PushEnactment] @id , @clauseNum;
        EXEC ( @statement );
        EXEC [Imperium].[PopEnactment];
      END TRY
      BEGIN CATCH
        DECLARE @msg nvarchar(1000);
        EXEC [sys].[xp_sprintf]
          @msg OUTPUT ,
          'Error enacting law ''%s'', clause ''%s'' (%s.%s).' ,
          @name , @cTitle , @id , @clauseNum;
        PRINT( @msg );
        IF @xc = 0
          ROLLBACK TRANSACTION;
        ELSE
          ROLLBACK TRANSACTION @sp;
        SET @errorMessage = ERROR_MESSAGE();
        THROW;
      END CATCH
      FETCH NEXT FROM [ClauseCursor] INTO @cTitle , @english , @statement;
    END

  CLOSE [ClauseCursor];
  DEALLOCATE [ClauseCursor];

  IF @xc = 0
    COMMIT TRANSACTION [Enact];
  SET @lawId = @id;

  SET NOCOUNT OFF;
  RETURN 0;
END" ) ,
    ( 2 , 10 ,
      "Recitation of Laws" ,
"To [recite][1] from the [Book of Laws][2] is to read all the ID and name a
specified law, followed by the number, name, English statement, and SQL
statement of each of its [clauses][3] or a specified clause.

  [1]: OBJECT::[Imperium].[Recite]
  [2]: OBJECT::[Imperium].[Laws]
  [3]: OBJECT::[Imperium].[Clauses]" ,
"CREATE PROCEDURE [Imperium].[Recite]
  @law sql_variant ,
  @clauseNum int = NULL
  WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @lawId nvarchar(30) ,
          @lawName sysname ,
          @enactedOn nvarchar(30) ,
          @enactedBy sysname ,
          @clauseName sysname ,
          @hr nvarchar(77) = REPLACE( SPACE(77) , ' ' , '*' ) ,
          @english nvarchar(4000) ,
          @statement nvarchar(4000);
  IF @law IS NULL
    RETURN;
  SELECT TOP (1)
      @lawId = CAST( [Id] AS nvarchar(30)) ,
      @lawName = [Name] ,
      @enactedOn = CONVERT( nvarchar(30) , [EnactedOn] , 20 ) ,
      @enactedBy = USER_NAME ( [EnactedBy] )
    FROM [Imperium].[Laws]
    WHERE
      [Id] = CASE
          WHEN SQL_VARIANT_PROPERTY( @law , 'BaseType' )
               IN( 'smallint' , 'tinyint' , 'bigint' , 'int' )
          THEN CAST( @law AS bigint )
          ELSE [Id]
        END AND
      [Name] = CASE
          WHEN SQL_VARIANT_PROPERTY( @law , 'BaseType' )
               IN( 'varchar', 'nvarchar' )
          THEN CAST( @law AS sysname )
          ELSE [Name]
        END
    ORDER BY [Id] ASC;

  PRINT '-- # IMPERIAL LAW ' + @lawId;
  PRINT '-- ' + @lawName;
  PRINT '-- enacted on ' + @enactedOn;
  PRINT '--         by ' + @enactedBy;
  PRINT '';

  DECLARE [ClauseCursor] CURSOR
    FOR SELECT
            ISNULL( NULLIF( [Name] , '' ) , '(unnamed clause)' ) ,
            CAST( [ClauseNumber] AS nvarchar(30)),
            LTRIM( RTRIM( [English] )),
            LTRIM( RTRIM( [Statement] ))
          FROM [Imperium].[Clauses]
          WHERE [LawId] = @lawId AND
                [ClauseNumber] = ISNULL( @clauseNum , [ClauseNumber] )
          ORDER BY [ClauseNumber];
  OPEN [ClauseCursor];
  FETCH NEXT FROM [ClauseCursor]
    INTO @clauseName , @clauseNum , @english , @statement;
  WHILE( @@FETCH_STATUS = 0 )
    BEGIN
      DECLARE @cnum nvarchar( 30 ) = CAST( @clauseNum AS nvarchar(30) );
      PRINT '/*' + @hr;
      PRINT ' * ' + @lawId + '.' + @cnum + ': ' + @clauseName;
      DECLARE @n int = CHARINDEX( CHAR(13) + CHAR(10) , @english );
      WHILE( @n > 0 )
        BEGIN
          PRINT ' * ' + SUBSTRING( @english , 0, @n + 2 );
          SET @english = SUBSTRING( @english , @n + 2, LEN( @english ));
          SET @n = CHARINDEX( CHAR(13) + CHAR(10) , @english );
        END
      PRINT ' * ' + @english;
      PRINT @hr + '*/';

      PRINT 'GO';
      PRINT @statement;
      PRINT 'GO';
      PRINT '';

      FETCH NEXT FROM [ClauseCursor]
        INTO @clauseName , @clauseNum , @english , @statement;
    END
  CLOSE [ClauseCursor];
  DEALLOCATE [ClauseCursor];
END" ) ,
    ( 2 , 11 ,
      "The First Page of the Book of History" ,
"The following objects shall be recoreded in the [Book of History][1]:

  * the foundation of [The Imperium][2]
  * the office of [The Imperitor][3]
  * the creation of the [Book of Laws][4]
  * the definition of [clauses][5]
  * the definition of [clause tables][6]
  * the creation of the Book of History
  * the creation of the [enactment stack][7]
  * the procedure of [pushing to the enactment stack][8]
  * the procedure of [popping from the enactment stack][9]
  * the procedure of [recording history][10]
  * the procedure of [enacting laws][11]
  * the procedure of [reading from the Book of Laws][12]

  [1]: OBJECT::[Imperium].[History]
  [2]: SCHEMA::[Imperium]
  [3]: ROLE::[Imperitor]
  [4]: OBJECT::[Imperium].[Laws]
  [5]: OBJECT::[Imperium].[Clauses]
  [6]: OBJECT::[Imperium].[ClauseTable]
  [7]: OBJECT::[Imperium].[EnactmentStack]
  [8]: OBJECT::[Imperium].[PushEnactment]
  [9]: OBJECT::[Imperium].[PopEnactment]
  [10]: TRIGGER::[RecordHistory]
  [11]: OBJECT::[Imperium].[Enact]
  [12]: OBJECT::[Imperium].[Recite]" ,
"INSERT [Imperium].[History]
    ( [EventType] ,
      [ObjectType] ,
      [ObjectName] ,
      [SchemaName] ,
      [LawId] ,
      [ClauseNumber] )
  VALUES
    ( 'CREATE_SCHEMA' , 'SCHEMA' , 'Imperium' , NULL , 1 , 1 ) ,
    ( 'CREATE_ROLE' , 'ROLE' , 'Imperitor' , NULL , 1 , 2 ) ,
    ( 'GRANT_DATABASE' , 'SCHEMA' , 'Imperium' , '' , 1 , 2 ) ,
    ( 'ADD_ROLE_MEMBER' , 'SQL USER' , 'Archon' , '' , 1 , 3 ) ,
    ( 'CREATE_TABLE' , 'TABLE' , 'Laws' , 'Imperium' , 2 , 1 ) ,
    ( 'CREATE_TABLE' , 'TABLE' , 'Clauses' , 'Imperium' , 2 , 2 ) ,
    ( 'CREATE_TYPE' , 'TYPE' , 'ClauseTable' , 'Imperium' , 2 , 3 ) ,
    ( 'CREATE_TABLE' , 'TABLE' , 'History' , 'Imperium' , 2 , 4 ) ,
    ( 'CREATE_TABLE' , 'TABLE' , 'EnactmentStack' , 'Imperium' , 2 , 5 ) ,
    ( 'CREATE_PROCEDURE' , 'PROCEDURE' , 'PushEnactment' , 'Imperium' , 2 , 6 ) ,
    ( 'CREATE_PROCEDURE' , 'PROCEDURE' , 'PopEnactment' , 'Imperium' , 2 , 7 ) ,
    ( 'CREATE_TRIGGER' , 'TRIGGER' , 'RecordHistory' , '' , 2 , 8 ) ,
    ( 'CREATE_PROCEDURE' , 'PROCEDURE' , 'Enact' , 'Imperium' , 2 , 9 ) ,
    ( 'CREATE_PROCEDURE' , 'PROCEDURE' , 'Read' , 'Imperium' , 2 , 10 );" );

/*******************************************************************************
 * 2.11 : The First Page of the Book of History
 * The following objects shall be recoreded in the [Book of History][1]:
 *
 *   * the foundation of [The Imperium][2]
 *   * the office of [The Imperitor][3]
 *   * the creation of the [Book of Laws][4]
 *   * the definition of [clauses][5]
 *   * the definition of [clause tables][6]
 *   * the creation of the Book of History
 *   * the creation of the [enactment stack][7]
 *   * the procedure of [pushing to the enactment stack][8]
 *   * the procedure of [popping from the enactment stack][9]
 *   * the procedure of [recording history][10]
 *   * the procedure of [enacting laws][11]
 *   * the procedure of [reading from the Book of Laws][12]
 *
 *   [1]: OBJECT::[Imperium].[History]
 *   [2]: SCHEMA::[Imperium]
 *   [3]: ROLE::[Imperitor]
 *   [4]: OBJECT::[Imperium].[Laws]
 *   [5]: OBJECT::[Imperium].[Clauses]
 *   [6]: OBJECT::[Imperium].[ClauseTable]
 *   [7]: OBJECT::[Imperium].[EnactmentStack]
 *   [8]: OBJECT::[Imperium].[PushEnactment]
 *   [9]: OBJECT::[Imperium].[PopEnactment]
 *   [10]: TRIGGER::[RecordHistory]
 *   [11]: OBJECT::[Imperium].[Enact]
 *   [12]: OBJECT::[Imperium].[Read]
********************************************************************************/
GO
INSERT [Imperium].[History]
    ( [EventType] ,
      [ObjectType] ,
      [ObjectName] ,
      [SchemaName] ,
      [LawId] ,
      [ClauseNumber] )
  VALUES
    ( 'CREATE_SCHEMA' , 'SCHEMA' , 'Imperium' , '' , 1 , 1 ) ,
    ( 'CREATE_ROLE' , 'ROLE' , 'Imperitor' , '' , 1 , 2 ) ,
    ( 'GRANT_DATABASE' , 'SCHEMA' , 'Imperium' , '' , 1 , 2 ) ,
    ( 'ADD_ROLE_MEMBER' , 'SQL USER' , 'Archon' , '' , 1 , 3 ) ,
    ( 'CREATE_TABLE' , 'TABLE' , 'Laws' , 'Imperium' , 2 , 1 ) ,
    ( 'CREATE_TABLE' , 'TABLE' , 'Clauses' , 'Imperium' , 2 , 2 ) ,
    ( 'CREATE_TYPE' , 'TYPE' , 'ClauseTable' , 'Imperium' , 2 , 3 ) ,
    ( 'CREATE_TABLE' , 'TABLE' , 'History' , 'Imperium' , 2 , 4 ) ,
    ( 'CREATE_TABLE' , 'TABLE' , 'EnactmentStack' , 'Imperium' , 2 , 5 ) ,
    ( 'CREATE_PROCEDURE' , 'PROCEDURE' , 'PushEnactment' , 'Imperium' , 2 , 6 ) ,
    ( 'CREATE_PROCEDURE' , 'PROCEDURE' , 'PopEnactment' , 'Imperium' , 2 , 7 ) ,
    ( 'CREATE_TRIGGER' , 'TRIGGER' , 'RecordHistory' , '' , 2 , 8 ) ,
    ( 'CREATE_PROCEDURE' , 'PROCEDURE' , 'Enact' , 'Imperium' , 2 , 9 ) ,
    ( 'CREATE_PROCEDURE' , 'PROCEDURE' , 'Recite' , 'Imperium' , 2 , 10 );
GO
