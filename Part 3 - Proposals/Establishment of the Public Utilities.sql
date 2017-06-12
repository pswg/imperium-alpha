SET QUOTED_IDENTIFIER OFF;

DECLARE @name sysname , @preamble nvarchar( 1000 );
SET @name = "Establishment of the Public Utilities";
SET @preamble =
"For the promotion of the general welfare essential for the enjoyment by all
the people of the blessings of democracy, the Senate of the Imperium hereby
proposes,";
DECLARE @clauses [Imperium].[ClauseTable];
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Establishment of the Public Utilities" ,
"There shall be a set of objects, collectively referred to as the [public
utilities][1] of the Imperium.

  [1]: SCHEMA::[Util]" ,
"CREATE SCHEMA [Util];" ) ,
    ( "Access to Public Utilities" ,
"All [citizens][1] shall have the right to invoke or review any [public
utility][2] of the Imperium.

  [1]: ROLE::[Citizen]
  [2]: SCHEMA::[Util]" ,
"GRANT EXECUTE , VIEW DEFINITION ON SCHEMA::[Util] TO [Citizen];" ) ,
    ( "The Recite Utility" ,
"To [recite][1] a given name, preamble, [table of clauses][2], and optional
identifer is to perform the following procedure:

 1. read said identifier, name, and preamble
 2. read each clause's clause number, name, and English and SQL statements.

  [1]: OBJECT::[Util].[Recite]
  [1]: TYPE::[Imperium].[ClauseTable]" ,
"CREATE PROCEDURE [Util].[Recite]
  @name sysname ,
  @preamble nvarchar( 1000 ) ,
  @clauses [Imperium].[ClauseTable] READONLY ,
  @ident nvarchar( 30 ) = '_'
  WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @clauseNum int ,
          @eng nvarchar( 4000 ) ,
          @sql nvarchar( 4000 ) ,
          @eol nchar( 2 ) = char( 13 ) + char( 10 ) ,
          @pf nchar( 3 ) = ' * ' ,
          @hr nvarchar( 78 ) = REPLACE( SPACE( 78 ) , ' ' , '*' );
  SET @name = LTRIM( RTRIM( @name ) );
  SET @eng = @pf + LTRIM( RTRIM( REPLACE( @preamble , @eol , @eol + @pf ) ) );

  PRINT '/*' + @hr;
  PRINT CONCAT( @pf , @ident , ': ' , @name );
  PRINT @eng;
  PRINT @hr + '*/';
  PRINT '';

  DECLARE [ClauseCursor] CURSOR
    FOR SELECT
            ISNULL( NULLIF( [Name] , '' ) , '(unnamed clause)' ) ,
            CAST( [ClauseNumber] AS nvarchar( 30 ) ) ,
            @pf + LTRIM( RTRIM( REPLACE( [English] , @eol , @eol + @pf ) ) ) ,
            LTRIM( RTRIM( [Statement] ) )
          FROM @clauses
          ORDER BY [ClauseNumber];
  OPEN [ClauseCursor];
  FETCH NEXT FROM [ClauseCursor]
    INTO @name , @clauseNum , @eng , @sql;
  WHILE( @@FETCH_STATUS = 0 )
    BEGIN
      DECLARE @cnum nvarchar( 30 ) = CAST( @clauseNum AS nvarchar( 30 ) );
      PRINT '/*' + @hr;
      PRINT CONCAT( @pf , @ident , '.' , @clauseNum , ': ' , @name );
      PRINT @eng;
      PRINT @hr + '*/';

      PRINT 'GO';
      PRINT @sql;
      PRINT 'GO';
      PRINT '';

      FETCH NEXT FROM [ClauseCursor]
        INTO @name , @clauseNum , @eng , @sql;
    END
  CLOSE [ClauseCursor];
  DEALLOCATE [ClauseCursor];
  RETURN 0;
END" ) ,
    ( "Recitation of Laws" ,
"To [recite a law][1] with a given law ID or name and optional clause number
or name is to perform the following procedure:

 1. identify a single [law][2] that matches said law ID or name
 2. if no law ID or name is provided, or if no law was found matching said
    value, raise an error and stop
 3. construct a [table of clauses][3] consisting of all [clauses][4] that
    are associated with said law
 4. if a clause number or name are provided, delete clauses from said table
    of clauses that do not match said clause number or name
 5. if the resulting clause table is empty, raise an error and stop
 6. read the ID of said law, the date and time said law was enacted, and the
    name of the person who enacted said law.
 7. [recite][5] the name and preamble of said law, said table of clauses, and
    ID of said law as identifier

  [1]: OBJECT::[Imperium].[Recite]
  [2]: OBJECT::[Imperium].[Laws]
  [3]: TYPE::[Imperium].[ClauseTable]
  [4]: OBJECT::[Imperium].[Clauses]
  [5]: OBJECT::[Util].[Recite]" ,
"CREATE PROCEDURE [Imperium].[Recite]
  @law sql_variant ,
  @clause sql_variant = NULL
  WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @lawId bigint = TRY_CAST( @law AS bigint ) ,
          @name sysname ,
          @preamble nvarchar( 1000 ) ,
          @enactedOn nvarchar( 30 ) ,
          @enactedBy sysname ,
          @err nvarchar( 400 ) ,
          @result int = -1;
  DECLARE @clauses [Imperium].[ClauseTable];
  IF @lawId IS NULL
    SELECT TOP(1) @lawId = [ID]
      FROM [Imperium].[Laws]
      WHERE [Name] = TRY_CAST( @law AS sysname )
      ORDER BY [Id] DESC;

  SELECT
      @lawId = [ID] ,
      @name = [Name] ,
      @preamble = [Preamble] ,
      @enactedOn = CONVERT( nvarchar( 30 ) , [EnactedOn] , 20 ) ,
      @enactedBy = USER_NAME ( [EnactedBy] ) ,
      @result = 0
    FROM [Imperium].[Laws]
    WHERE [Id] = @lawId;

  IF @lawId IS NULL
    BEGIN
      SET @err = CONCAT(
        'Law ''' ,
        CAST( @law AS sysname ) ,
        ''' not found.' );
      THROW 50000 , @err , 1;
    END

  INSERT @clauses( [Name] , [English] , [Statement] )
    SELECT [Name] , [English] , [Statement]
    FROM [Imperium].[Clauses]
    WHERE [LawId] = @lawId;

  IF @clause IS NOT NULL
    BEGIN
      DECLARE @cNum int = TRY_CAST( @clause AS int ) ,
              @cName int = TRY_CAST( @clause AS sysname );
      IF @cNum IS NOT NULL
        DELETE @clauses WHERE [ClauseNumber] = @cNum;
      ELSE IF @cName IS NOT NULL
        DELETE @clauses WHERE [Name] = @cName;
    END

  IF NOT EXISTS( SELECT * FROM @clauses )
    BEGIN
      SET @err = CONCAT(
        'Clause ''' ,
        CAST( @clause AS sysname ) ,
        ''' not found.' );
      THROW 50000 , @err , 1;
    END

  PRINT CONCAT( '-- IMPERIAL LAW #' , @lawId );
  PRINT CONCAT( '-- enacted on: ' , @enactedOn );
  PRINT CONCAT( '--         by: ' , @enactedBy );

  EXEC @result = [Util].[Recite]
    @name = @name ,
    @preamble = @preamble ,
    @clauses = @clauses ,
    @ident = @lawId;

  RETURN @result;
END" ) ,
    ( "Right to Recititation of Laws" ,
"All [citizens][1] shall have the right to [recite a law][2].

  [1]: Role::[Citizen]
  [2]: OBJECT::[Imperium].[Recite]" ,
"GRANT EXECUTE ON OBJECT::[Imperium].[Recite] TO [Citizen];" ) ,
    ( "Recitation of Bills" ,
"To [recite a bill][1] with a given bill ID or name and optional clause number
or name is to perform the following procedure:

 1. identify a single [bill][2] that matches said bill ID or name
 2. if no bill ID or name is provided, or if no bill was found matching said
    value, raise an error and stop
 3. construct a [table of clauses][3] consisting of all [clauses][4] that
    are associated with said bill
 4. if a clause number or name are provided, delete clauses from said table
    of clauses that do not match said clause number or name
 5. if the resulting clause table is empty, raise an error and stop
 6. read the ID of said bill, the date and time said bill was proposed, and
    the name of the person who proposed said bill.
 7. [recite][5] the name and preamble of said bill, said table of clauses, and
    ID of said bill as identifier

  [1]: OBJECT::[Senate].[Recite]
  [2]: OBJECT::[Senate].[Bills]
  [3]: TYPE::[Imperium].[ClauseTable]
  [4]: OBJECT::[Senate].[Clauses]
  [5]: OBJECT::[Util].[Recite]" ,
"CREATE PROCEDURE [Senate].[Recite]
  @bill sql_variant ,
  @clause sql_variant = NULL
  WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @billId bigint = TRY_CAST( @bill AS bigint ) ,
          @name sysname ,
          @preamble nvarchar( 1000 ) ,
          @proposedOn nvarchar( 30 ) ,
          @proposedBy sysname ,
          @err nvarchar( 400 ) ,
          @result int = -1;
  DECLARE @clauses [Imperium].[ClauseTable];
  IF @billId IS NULL
    SELECT TOP(1) @billId = [ID]
      FROM [Senate].[Bills]
      WHERE [Name] = TRY_CAST( @bill AS sysname )
      ORDER BY [Id] ASC;

  SELECT
      @billId = [ID] ,
      @name = [Name] ,
      @preamble = [Preamble] ,
      @proposedOn = CONVERT( nvarchar( 30 ) , [ProposedOn] , 20 ) ,
      @proposedBy = USER_NAME ( [ProposedBy] ) ,
      @result = 0
    FROM [Senate].[Bills]
    WHERE [Id] = @billId;

  IF @billId IS NULL
    BEGIN
      SET @err = CONCAT(
        'Bill ''' ,
        CAST( @bill AS sysname ) ,
        ''' not found.' );
      THROW 50000 , @err , 1;
    END

  INSERT @clauses( [Name] , [English] , [Statement] )
    SELECT [Name] , [English] , [Statement]
    FROM [Senate].[Clauses]
    WHERE [BillId] = @bill;

  IF @clause IS NOT NULL
    BEGIN
      DECLARE @cNum int = TRY_CAST( @clause AS int ) ,
              @cName int = TRY_CAST( @clause AS sysname );
      IF @cNum IS NOT NULL
        DELETE @clauses WHERE [ClauseNumber] = @cNum;
      ELSE IF @cName IS NOT NULL
        DELETE @clauses WHERE [Name] = @cName;
    END

  IF NOT EXISTS( SELECT * FROM @clauses )
    BEGIN
      SET @err = CONCAT(
        'Clause ''' ,
        CAST( @clause AS sysname ) ,
        ''' not found.' );
      THROW 50000 , @err , 1;
    END

  PRINT CONCAT( '-- SENATE BILL #' , @billId );
  PRINT CONCAT( '-- proposed on: ' , @proposedOn );
  PRINT CONCAT( '--          by: ' , @proposedBy );

  DECLARE @billIdent nvarchar( 30 ) = CONCAT( 'SB.' , @billId );
  EXEC @result = [Util].[Recite]
    @name = @name ,
    @preamble = @preamble ,
    @clauses = @clauses ,
    @ident = @billIdent;

  RETURN @result;
END" ) ,
    ( "Right to Recititation of Bills" ,
"All [citizens][1] shall have the right to [recite a bill][2].

  [1]: Role::[Citizen]
  [2]: OBJECT::[Senate].[Recite]" ,
"GRANT EXECUTE ON OBJECT::[Senate].[Recite] TO [Citizen];" );

EXEC [Senate].[Propose] @name , @preamble , @clauses;
GO
