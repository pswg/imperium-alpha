# Welcome to Alpha
### New Citizen Orientation Guide
***Congratulations!*** You’ve been granted citizenship in the Imperium of Alpha,
a fictional world housed within a SQL Server.

## Through the Gates
The lands of Alpha are guarded by the grand Gates of Alpha. To access Alpha,
you’ll first need a SQL Server client, such as SQL Server Management Studio, and
you’ll need the username and password provided to you by your citizenship
sponsor. Use the following login information:

 *  Server type: Database Engine
 *  Server name: provided by your sponspr
 *  Authentication: SQL Server Authentication
 *  Login: username provided by your sponsor
 *  Password: username provided by your sponsor
 *  With advanced options expanded, in the Connection Properties tab, set
    Connect to database: Alpha
    *  *NOTE:* This is required. Server-level logins will be rejected.

You’ll now be able to pass through the Gates of alpha Alpha. Enjoy your stay.

## Top 7 things to do in Alpha
 1. ***Safety First!*** You may change your password to anything you like, but
    remember to keep it safe when you are visiting Alpha and abroad. Once you
    log in, change your password with this script:

        ALTER USER [username]
          WITH PASSWORD = 'new password'
          OLD_PASSWORD = 'old password';

 2. ***Take Action!*** Many actions within the world of Alpha are limited by
    action points, or *AP*, and which take time regenerate. Get a head start by
    recovering your first AP while you’re getting familiar with the world by
    running this script:

        EXEC [Action].[Recover];

    You can always review your current number of AP using this query:

        SELECT [Value] FROM [My].[ActionPoints];

 3. ***Visit the Sacrum!*** According to legend, Alpha was created by a mysterious
    deity known as, the *Great Sa*, who created the world, then left, promising to
    return one day to end the world. Use this script to can read all about the
    Great Sa in the Codex Sagatus, housed within the Sacrum, the temple which
    predates even the Imperium:

        EXEC [Sacrum].[CodexSagatus];

 4. ***Civic Order!*** The world of Alpha is dominated by the grand empire known
    as the Imperium, a constitutional monarchy is ruled over by an individual
    known as the *Imperitor*. The current Imperitor is the benevolent god-king,
    *Archon*, a direct descendant of the Great Sa. Familiarize yourself with the
    laws of the Imperium by reviewing the Book of Laws:

        SELECT [Id] , [Name] , [Preamble] FROM [Imperium].[Laws];

    You can read an individual law in full using this script:

        EXEC [Imperium].[Recite] [The Book of Laws];

 5. ***Viva Democracy!*** Although the people of the Imperium enjoy the
    protection of the Imperitor, they also embrace democracy in the form of the
    *Imperial Senate*. Review any bills that have been proposed in the senate
    using this script:

        SELECT [Id] , [Name] , [Preamble] FROM [Senate].[Bills];

    View any bills that are currently open for voting using this script:

        SELECT [BillId] , [ElectionId] , [Name] , [OpenedOn] , [ClosedOn]
          FROM [Senate].[Bills] b
          JOIN [Senate].[CallsForVotes] c ON b.[Id] = c.[BillId]
          JOIN [Senate].[Elections] e ON c.[ElectionId] = e.[Id];

 6. ***Make your Voice Heard!*** Once you’ve familiarized yourself with your
    surroundings, it’s time to participate in the democratic process. Vote in an
    open election using a script like this:

        EXEC [Senate].[Vote] @electionId , 'yea' -- or 'nay'

 7. ***An Exceptional Proposal!*** You can even begin shaping the world of Alpha
    to your vision by proposing your own bills using a script like this:

        SET QUOTED_IDENTIFIER OFF;

        DECLARE @name sysname ,  @preamble nvarchar( 4000 );
        SET @name = "Bill name here";
        SET @preamble = "Bill preamble here";
        DECLARE @clauses [Imperium].[ClauseTable]
        INSERT @clauses
            ( [Name] , [English] , [Statement] )
          VALUES
            ( "Establishment of Titles" , 
        "English Description / Markdown here." , 
        "SQL STATEMENTS HERE" ) ,
            ... more clauses ... ;
        EXEC [Senate].[Propose] @name , @preamble , @clauses;
        GO


