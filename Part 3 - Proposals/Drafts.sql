SET QUOTED_IDENTIFIER OFF;

DECLARE @name sysname ,  @preamble nvarchar( 4000 );
SET @name = "Draft Bills";
SET @preamble =
"To make the proposing of bills easier, the Senate of the Imperium hereby
proposes,";
DECLARE @clauses [Imperium].[ClauseTable]
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Definition of Draft" ,
"A [draft][1] within the senate shall consist of a name, a preamble, the
person that owns the draft, the date and time the draft was created in the
senate, the person that drafted it, the date and time it was last edited,
and the person that last edited it, and one or more [draft clauses][2].

  [1]: OBJECT::[Senate].[Drafts]
  [2]: OBJECT::[Senate].[DraftClauses]" ,
"CREATE TABLE [Senate].[Drafts](
  [Id] bigint NOT NULL
              IDENTITY( 1 , 1 )
              PRIMARY KEY ,
  [Name] sysname NOT NULL ,
  [Preamble] nvarchar(4000) NOT NULL ,
  [OwnedBy] int NOT NULL ,
  [CreatedBy] int NOT NULL ,
  [CreatedOn] datetime NOT NULLL ,
  [LastEditedBy] int NOT NULL ,
  [LastEditedOn] datetime NOT NULL )
  WITH( DATA_COMPRESSION = PAGE );" ) ,
    ( "Definition of Draft Clauses" ,
"A [clause][1] of a [draft][2] shall consist of an optional name, a
description writen in clear, plain English and a valid, an executable SQL
statement, and a number indicating its position within the set of clauses of
the bill.

  [1]: OBJECT::[Senate].[DraftClauses]
  [2]: OBJECT::[Senate].[Drafts]" ,
"CREATE TABLE [Senate].[DraftClauses](
  [DraftId] bigint NOT NULL ,
  [ClauseNumber] int NOT NULL ,
  [Name] sysname NULL ,
  [English] nvarchar(4000) NOT NULL ,
  [Statement] nvarchar(4000) NOT NULL ,
  PRIMARY KEY( [DraftId] , [ClauseNumber] ) ,
  FOREIGN KEY( [DraftId] ) REFERENCES [Senate].[Drafts]( [Id]) )
  WITH( DATA_COMPRESSION = PAGE );" );
EXEC [Senate].[Propose] @name , @preamble , @clauses;
GO
