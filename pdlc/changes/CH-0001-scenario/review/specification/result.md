Result: fail

Remit: specification

Problems:
- pdlc/changes/CH-0001-scenario/change.md:131 · The line "The builder renamed the two names in `scenario`, and the 34 checks pass." gives a fact that does not agree with line 130. Line 130 says that "one name in `scenario` was not clear". Line 131 then says "the two names", and no noun in the same list item tells the reader which two names. The reader cannot tell if the builder renamed one name or two names. Write, for example, "The builder renamed `<old>` to `<new>` and `<old>` to `<new>` in `scenario`, and the 34 checks pass." Or, if only one name changed, write "one name". · DES-writing-style rule 4.1 (give accurate facts) and the local-references rule (a short noun must refer to a noun in the same paragraph)

Follow-ups: none

Notes:
- Earlier problem at change.md:130 (imperative "Send back to build") is fixed. Line 130 now reads "Verify returned the change to build, because one name in `scenario` was not clear." The sentence has a subject, uses the active voice, and has no phrasal verb.
- Earlier problem at change.md:131 (passive "the names of `scenario` are fixed") is fixed. The new line uses the active voice with the builder as the subject, and does not use "fixed". The new line causes the new problem above.
- Earlier problem at change.md:129 ("these ranges" with no referent) is fixed. Line 129 now says that JOB-simulate.R5 (bad command line) "limits `--days` and `--seed`".
- Line 132 ("Verify round 2: specification failed on the words of three log lines. Verify corrected the words, and no code changed.") follows the writing rules.
- The writing check gave no findings for the changed lines.
- The code, "Files", and the spec did not change since the earlier review. Thus, this review did not judge them again.
