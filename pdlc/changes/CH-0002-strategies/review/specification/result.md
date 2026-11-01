Result: fail

Remit: specification

Problems:
- pdlc/changes/CH-0002-strategies/change.md:136 · The text "The re-review passed." uses the short noun "the re-review", but no review is in the same list item. The reader must look back to the item above to find which review passed. Write, for example, "The second tests review passed." · DES-writing-style, the local-references rule (a short noun refers to a noun in the same paragraph, and a list item starts with the full noun)
- pdlc/changes/CH-0002-strategies/change.md:138 · The text "Verify round 1 failed on quality and specification. This failure is round 2 of 2." gives two round numbers for one failure, so the facts are not clear. Also, "failed on quality and specification" omits the noun "reviews". Write, for example, "In verify round 1, the quality review and the specification review failed. This failure uses round 2 of the 2 permitted rounds." · DES-writing-style 4.1 (accurate facts) and 4.2 (do not omit words)
- pdlc/changes/CH-0002-strategies/change.md:139 · The text "so no code changes" omits a subject or a verb. The words can mean "the code does not change" or "there are no code changes". Write, for example, "Thus, the code does not change." · DES-writing-style 4.2 (do not omit words) and 4.1 (accurate facts)
- pdlc/changes/CH-0002-strategies/change.md:140 · The text "IN-0004 (shift on a day with little sun) covers the other follow-up." uses the short noun "the other follow-up", but the list item names no follow-up before it. Write, for example, "Verify filed IN-0005 (guards on strategy inputs) for approval, for one follow-up of the review. IN-0004 (shift on a day with little sun) covers the second follow-up." · DES-writing-style, the local-references rule (a short noun refers to a noun in the same paragraph)

Follow-ups: none

Notes:
- Earlier problem 1 (item 1 of "Progress log": the omitted subject and the pronoun "both") is fixed. Line 134 now has full sentences and names CH-0003 (simulation), the scenario and the strategies.
- Earlier problem 2 (item 2 of "Progress log": "with hours apart" and "round 1 of 2") is fixed. Line 135 now says that a wrong `shift` with three hours in a row passed the R5 (load shift into sun) checks, and "This review is round 1 of 2" has a subject and a verb.
- Line 134 starts with "The change". In a change spec, this short noun clearly means CH-0002 (battery and load strategies), so I do not count it as a problem.
- Line 136 says "a check whose three sunniest hours are not next to each other". The hours belong to the input day of the check, not to the check. I judge the meaning clear enough, so I do not count it as a problem.
- The code in `StoragePolicySim/Strategy.lean` did not change since the earlier review. Thus, this re-review does not judge the code again.
- The "Writing check" section of the packet has no findings.
