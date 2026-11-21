# Review packet · CH-0002-strategies · specification

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 91e87a56cfeac263c83ce316d1fe6e10a89cd347

## Re-review

Earlier review: 8e9c0b3c9f38fc8845a17585a59e2012b6088332

An earlier review of this remit judged this change at 8e9c0b3c9f38. Judge only these two things:

1. Each earlier problem below. If the problem is not fixed, list it again under "Problems".
2. The changes since the earlier review, in the diff below. List a new problem only
   where a changed line causes the problem.

Do not raise a new problem on material that did not change. This rule also applies
to a problem that the earlier review missed.

### Earlier problems

- pdlc/changes/CH-0002-strategies/change.md:141 · The text "is not a round in this project" does not say what a round is. The changed log lines removed each other mention of verify rounds, so no noun in the log tells the reader that "a round" is one of the permitted verify rounds. Write, for example, "The user decided that a review failure only on the words of pdlc records does not use one of the permitted verify rounds." · DES-writing-style 4.1 (accurate facts, not abstract statements) and 1.11 (one technical noun for one item)

### Changes since the earlier review

````
diff --git a/pdlc/changes/CH-0002-strategies/change.md b/pdlc/changes/CH-0002-strategies/change.md
index 74ec887..ed2afd6 100644
--- a/pdlc/changes/CH-0002-strategies/change.md
+++ b/pdlc/changes/CH-0002-strategies/change.md
@@ -138,4 +138,4 @@ none
 - The first verify failed on the quality review and the specification review.
 - The quality review asked for DES-writing-style (writing rules). `make_packets.py` gives that spec only to the specification review. The quality remit does not judge writing, so the builder changed no code.
 - Verify filed IN-0005 (guards on strategy inputs) for approval. IN-0004 (shift on a day with little sun) already covers the follow-up about days with little sun.
-- The user decided that a failure only on the words of pdlc records is not a round in this project.
+- The user decided that a review failure only on the words of pdlc records does not use one of the permitted verify rounds.
````

# Remit: specification

Default: yes

You judge if the code does what the spec says. You do not see the checks.

- The code meets the acceptance lines of each requirement. For a requirement marked
  `(retire)`, the change removes the code that served the requirement instead.
- The code does nothing that the spec did not ask for.
- Only the files in "Files" changed. In a file that "Files" lists with parts, only those
  parts changed. The change stays in its one scope. A job change must not edit the code of
  a capability.
- No old wording survives. The title and the summary of the spec, the cross-references in
  its requirements, and a README in "Files" show the behaviour as it is now. They include
  what the change adds. Nothing that the change removes or changes still shows the old
  way. The README says how to run the checks, and names any seam that a user can set.
- The spec text, the README text, and the code comments in the change follow the writing
  rules (`DES-writing-style`, in the packet). Each break of a rule is a problem. Give the
  line and the rule.
- Each finding under "Writing check" in the packet is a problem, unless you judge the
  finding to be a false alarm. For each false alarm, say why under "Notes".
- On a re-review, the writing check covers only the lines that changed since the earlier
  review.

## The change spec

````
# CH-0002 · Battery and load strategies

Intent: IN-0001 · Scope: CAP-strategies · Status: building · Ticket: none · Branch: pdlc/CH-0002-strategies · Base: pdlc/CH-0001-scenario

Tests-Locked: 91d1e6b

## Delivers

The library has four named strategies. Each strategy asks the battery to charge or to
discharge for an hour, and places the flexible load of a day.

## Requirements

### CAP-strategies.R1 · Strategy names

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

- Given a surplus of 2 kWh at 12:00, when `evening` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 16:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 17:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 23:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 00:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `evening` places the day, then the flexible load does not change.

### CAP-strategies.R5 · Load shift into sun

- Given a surplus of 2 kWh at 12:00, when `shift` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `shift` decides, then it asks to discharge 1.5 kWh.
- Given 3 kWh of flexible load and the most sun at 13:00, 11:00 and 12:00, when `shift` places the day, then each gets 1 kWh.
- Given equal sun from 10:00 to 14:00, when `shift` places 3 kWh of flexible load, then 10:00, 11:00 and 12:00 get 1 kWh each.
- Given 3 kWh of flexible load and no sun, when `shift` places the day, then the flexible load stays at 18:00, 19:00 and 20:00.
- Given 0 kWh of flexible load and sun at 12:00, when `shift` places the day, then each hour has 0 kWh of flexible load.

## Relies on

- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

All entries are in the namespace `StoragePolicySim`, in `StoragePolicySim/Strategy.lean`. A
check imports `StoragePolicySim.Strategy` and opens `StoragePolicySim`. No entry can fail,
so no entry has an error code.

- `inductive Strategy | none | greedy | evening | shift` with `BEq`, `Repr` and `Inhabited`
  (assumed). Write each value in full, for example `Strategy.none`, so that it does not
  mean `Option.none`.
- `Strategy.all : List Strategy`: `[.none, .greedy, .evening, .shift]`.
- `Strategy.name : Strategy → String`: `"none"`, `"greedy"`, `"evening"` or `"shift"`.
- `Strategy.ofName? (name : String) : Option Strategy`: the strategy whose name matches
  exactly, or `Option.none`.
- `structure Request` with `Repr` (assumed). The fields are `chargeKwh : Float` and
  `dischargeKwh : Float`: the energy that the strategy asks to charge and to discharge.
- `Strategy.decide (s : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request`.
  The hour is 0 to 23, and hour 17 is 17:00 to 18:00. The surplus is the solar energy that
  the house does not use directly. The shortfall is the load that the solar energy does not
  meet. One of the two is 0.
- `Strategy.placeFlex (s : Strategy) (pvKwh flexKwh : Array Float) : Array Float`. Each array
  has 24 items, one for each hour of a day. `pvKwh` is the solar energy of each hour, and
  `flexKwh` is the flexible load at its default hours. The result is the flexible load of
  each hour after the strategy places it.

### Test seams

none

## Files

- `StoragePolicySim/Strategy.lean`

## Check files

- `tests/CAP-strategies.lean`

## Steps

### Step 1 · Strategy names · [x]

- Requirement: CAP-strategies.R1
- Check: the checks named `CAP-strategies.R1 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 2 · No battery use · [x]

- Requirement: CAP-strategies.R2
- Check: the checks named `CAP-strategies.R2 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 3 · Greedy battery use · [x]

- Requirement: CAP-strategies.R3
- Check: the checks named `CAP-strategies.R3 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 4 · Evening battery use · [x]

- Requirement: CAP-strategies.R4
- Check: the checks named `CAP-strategies.R4 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

### Step 5 · Load shift into sun · [x]

- Requirement: CAP-strategies.R5
- Check: the checks named `CAP-strategies.R5 …` in `tests/CAP-strategies.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- The change comes after CH-0001 (scenario). CH-0003 (simulation) needs the scenario and the strategies. The strategies do not need the scenario.
- The first tests review failed, because a wrong `shift` that takes three hours in a row passed the checks of R5 (load shift into sun).
- The test writer then added a check whose three sunniest hours are not next to each other. The second tests review passed.
- Build: the 35 checks of `tests/CAP-strategies.lean` and the 34 checks of `tests/CAP-scenario.lean` pass. No check changed since the lock `91d1e6b`.
- The first verify failed on the quality review and the specification review.
- The quality review asked for DES-writing-style (writing rules). `make_packets.py` gives that spec only to the specification review. The quality remit does not judge writing, so the builder changed no code.
- Verify filed IN-0005 (guards on strategy inputs) for approval. IN-0004 (shift on a day with little sun) already covers the follow-up about days with little sun.
- The user decided that a review failure only on the words of pdlc records does not use one of the permitted verify rounds.
````

## The spec it covers: title and summary

````
# CAP-strategies · Battery and load strategies to compare

Status: active

## What it is for

CAP-strategies (battery and load strategies) holds the rules that the simulation compares.
Each strategy has a name. For each hour, a strategy asks the battery to charge or to
discharge. For each day, a strategy also places the flexible load.

The four strategies are these:

- `none`: no battery use.
- `greedy`: battery use at any hour.
- `evening`: discharge only in the evening.
- `shift`: greedy battery use, and the flexible load in the sunniest hours.

## Code map

- `StoragePolicySim/Strategy.lean`
````

## The requirements, in full

### CAP-strategies.R1 · Strategy names

Status: built · Intents: IN-0001

The list of strategies is `none`, `greedy`, `evening` and `shift`, in this order (assumed).
A name finds its strategy only when the name matches exactly (assumed).

- Given the list of strategies, when a caller reads it, then the names are none, greedy, evening and shift, in this order.
- Given the name "greedy", when a caller finds the strategy, then the result is the greedy strategy.
- Given the name "Greedy", when a caller finds the strategy, then there is no result.
- Given the name "", when a caller finds the strategy, then there is no result.

### CAP-strategies.R2 · No battery use

Status: built · Intents: IN-0001

The `none` strategy never asks the battery to charge or to discharge. It keeps the
flexible load at its default hours.

- Given a surplus of 2 kWh at 12:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 19:00, when `none` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `none` places the day, then the flexible load does not change.

### CAP-strategies.R3 · Greedy battery use

Status: built · Intents: IN-0001

The `greedy` strategy asks to charge with each surplus, and to discharge for each shortfall,
at any hour. It keeps the flexible load at its default hours. The simulation applies the
limits of the battery.

- Given a surplus of 2 kWh at 12:00, when `greedy` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 13:00, when `greedy` decides, then it asks to charge 0 kWh and to discharge 1.5 kWh.
- Given no surplus and no shortfall, when `greedy` decides, then it asks to charge 0 kWh and to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `greedy` places the day, then the flexible load does not change.

### CAP-strategies.R4 · Evening battery use

Status: built · Intents: IN-0001

The `evening` strategy charges as `greedy` does. It discharges only from 17:00 to 23:59
(assumed), to keep the stored energy for the evening peak. It keeps the flexible load at its
default hours.

- Given a surplus of 2 kWh at 12:00, when `evening` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 16:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 17:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 23:00, when `evening` decides, then it asks to discharge 1.5 kWh.
- Given a shortfall of 1.5 kWh at 00:00, when `evening` decides, then it asks to discharge 0 kWh.
- Given 1 kWh of flexible load at 18:00, 19:00 and 20:00, when `evening` places the day, then the flexible load does not change.

### CAP-strategies.R5 · Load shift into sun

Status: built · Intents: IN-0001

The `shift` strategy uses the battery as `greedy` does. It also moves the flexible load of
each day, in equal parts, to the three hours with the most solar output (assumed). A tie
goes to the earlier hour (assumed). A day with no solar output keeps its default hours.

- Given a surplus of 2 kWh at 12:00, when `shift` decides, then it asks to charge 2 kWh and to discharge 0 kWh.
- Given a shortfall of 1.5 kWh at 03:00, when `shift` decides, then it asks to discharge 1.5 kWh.
- Given 3 kWh of flexible load and the most sun at 13:00, 11:00 and 12:00, when `shift` places the day, then each gets 1 kWh.
- Given equal sun from 10:00 to 14:00, when `shift` places 3 kWh of flexible load, then 10:00, 11:00 and 12:00 get 1 kWh each.
- Given 3 kWh of flexible load and no sun, when `shift` places the day, then the flexible load stays at 18:00, 19:00 and 20:00.
- Given 0 kWh of flexible load and sun at 12:00, when `shift` places the day, then each hour has 0 kWh of flexible load.

## Specs it relies on

### DES-errors

````
# DES-errors · The project's error codes

Status: agreed · Default: yes · Ask at init: no

## Rule

Each error that the system can give has a code here, in `UPPER_SNAKE_CASE`. Acceptance
lines, Interface entries, and checks all use these codes. Thus, a check can expect the
exact error.

| Code | Meaning | Whose fault | Retry helps? |
|---|---|---|---|
| `UNKNOWN_COMMAND` | The first word of the command line is not a command | caller | no |
| `UNKNOWN_OPTION` | An option or a word that the command does not take | caller | no |
| `MISSING_VALUE` | An option that needs a value comes last, with no value | caller | no |
| `BAD_NUMBER` | The value of a number option is not a number of the right form | caller | no |
| `OUT_OF_RANGE` | A number is outside the range of its option | caller | no |
| `UNKNOWN_STRATEGY` | The name of the strategy is not in the list of strategies | caller | no |

When a requirement needs a new error, add a row. When the meaning is the same, use the
existing code again.

Add rows at intake and ready. Do not add a row while a change is in tests, build, or
verify. When you add a row, leave `Default:` as it is. Write each row the same way:

- The code in backticks.
- "Whose fault": `caller`, `system`, or `outside service`.
- "Retry helps?": `yes` or `no`.

Checks and the code of the app match on the error code. Each requirement decides what a
person sees, for example a message or a status. The message or the status can omit the
error code. If the caller cannot see the error code, a check expects the exact message and
status instead.

## Why

A check that expects "an error" passes for any error, also for a typo. A named code makes
the check exact. A named code also gives callers a stable value to handle.
````

### DES-writing-style

````
# DES-writing-style · How pdlc writes

Status: agreed · Default: yes · Ask at init: yes

## Rule

This rule is a copy of `WRITING-GUIDELINES.md` from the pskills repository.

These guidelines apply to all writing in this repository. They also apply to all text that
an agent writes when it uses the skills in this repository. They have four parts:

1. Part 1 gives the rules of ASD-STE100 Simplified Technical English (STE) in short form.
2. Part 2 gives two more rules: the local-references rule and the described-IDs rule.
3. Part 3 tells you how to apply the rules to each type of text.
4. Part 4 tells you how to examine your text against the rules.

### Where these guidelines apply

Use these guidelines for all of these types of text:

- The replies that an agent writes to the user in a conversation.
- Skills: the `SKILL.md` file, its reference files, and its templates.
- Agent definitions, system prompts, and the prompts that an agent writes for other agents.
- The documents that a skill or an agent writes: specs, designs, plans, reports, and web
  pages.
- Commit messages, pull request text, and code comments.

These items are not prose. Do not change them to obey the rules:

- Code, commands, file paths, and identifiers.
- Error codes, field names, and values.
- Header fields, for example `Intent:`, `Scope:`, `Status:`, `Branch:`, and `Base:`. A
  script reads each value. Thus, a header field holds only the bare value, with no name
  and no backticks. Write `Intent: IN-0001`, not `Intent: IN-0001 (poll-input-errors)`.
- Quoted text. For example, the words of a user, or the trigger phrases in the description
  of a skill.
- The names of products, organisations, and published works.

### Part 1: STE rules

STE is a controlled language for technical text. The standard has 53 rules in nine
sections, and a dictionary of approved words. This part gives the rules in short form,
with the rule numbers of the standard. This repository does not contain the dictionary.
Part 4 tells you how to get the dictionary and how to use it.

#### Words (STE section 1)

- **1.1** Use approved words, technical nouns, and technical verbs.
- **1.2 to 1.4** Use an approved word only as its approved part of speech. Use the word
  only with its approved meaning and in its approved forms. For example, "check" is
  approved as a noun. As a verb, write "make sure that".
- **1.5, 1.6, 1.8 to 1.10** Technical nouns are the names of items in your subject.
  Examples in software are "commit", "branch", "file", "schema", and "pull request". Use
  the terms that your project uses. Select short terms. Do not use slang or jargon.
- **1.7** Do not use a technical noun as a verb. For example, do not write "action the
  ticket". Write "close the ticket".
- **1.11** Use one technical noun for one item. Do not use a different noun for the same
  item in a different part of the text.
- **1.12, 1.13** Technical verbs are the actions in your subject. In software, "commit",
  "merge", "deploy", "parse", and "click" are technical verbs. Do not use a technical verb
  as a noun. Write "merge the branch", not "do a merge of the branch".
- **1.14** Use New Zealand English spelling, for example "behaviour", "colour", and
  "organise". STE uses American English unless your own rules give a different standard.
  These guidelines give New Zealand English. Do not change the spelling of code, field
  names, or quoted text.

#### Multi-word nouns (STE section 2)

- **2.1** Do not write a multi-word noun of more than three words. For example, do not
  write "test result cache file path". Write "the path of the cache file for test
  results".
- **2.2** If a technical noun has more than three words, write it in full one time. Then
  use a shorter form, or join the words with hyphens.

#### Verbs (STE section 3)

- **3.1, 3.2** Use only these verb forms:
  - The infinitive: "to run".
  - The imperative: "Run the tests."
  - The simple present, the simple past, and the simple future: "runs", "ran", "will run".
  - The past participle as an adjective: "the merged branch".
- **3.3** Use the past participle as an adjective, for example "the merged branch".
- **3.4** Do not use auxiliary verbs to make complex verb constructions. For example, do
  not write "the file should have been updated". Write "update the file".
- **3.5** Use the "-ing" form of a verb only in a technical noun, for example "load
  balancing". Do not write "When running the tests, read the log". Write "When you run
  the tests, read the log".
- **3.6** Use the active voice. In descriptive text, you can use the passive voice only
  when you do not know who or what does the action.
- **Modal verbs (3.2, 3.4).** STE has "must" and "can". It does not have "should" or "may".
  Keep the strength of the original text:
  - A rule that always holds: write "must" or "must not".
  - Advice or a default: write "Try to …" or "Usually, …". Do not write "must".
  - A permission: write "is permitted to …". Write "can" for an ability.
  - The word "never": write "Do not …".
- **3.7** Use a verb to show an action, not a noun. Write "install the package", not "do
  the installation of the package".

#### Sentences (STE section 4)

- **4.1** Write short and clear sentences. Give one topic in each sentence. Give accurate
  facts, not abstract statements. For example, do not write "Large inputs change the run
  time". Write "When the input has more than 1,000 rows, the run time increases".
- **4.2** Do not omit words to make a sentence shorter. Do not omit articles, verbs, or
  subjects. Do not use contractions. Write "do not", not "don't".
- **4.3** Use a vertical list for complex text.
- **4.4** Use connecting words to connect related sentences, for example "and", "but",
  "then", "thus", and "as a result".
- **4.5** When applicable, put "the", "a", "an", "this", or "these" before a noun.

#### Instructions (STE section 5)

STE calls this type of text a procedure.

- **5.1** Write a maximum of 20 words in each instruction.
- **5.2** Write only one instruction in each sentence, unless the actions occur at the
  same time.
- **5.3** Write instructions in the imperative: "Run the tests."
- **5.4** If the reader must know a condition first, start with the condition. Put a comma
  after the condition: "If the tests fail, stop."
- **5.5** Use a note only to give information, not to give an instruction.

#### Descriptive text (STE section 6)

Descriptive text gives information, not instructions. Do not use the imperative in
descriptive text.

- **6.1** Give information gradually. Give the primary point first, then the details.
- **6.2** Use key words and headings to show the structure of the text.
- **6.3** Write a maximum of 25 words in each descriptive sentence.
- **6.4 to 6.6** Use paragraphs to show related information. Give each paragraph only one
  topic. Write a maximum of six sentences in each paragraph.

#### Safety instructions (STE section 7)

In software, a safety instruction tells the reader about an action that can cause loss of
data or other damage. Examples are a force push, a deleted table, and a message to other
persons.

- **7.1** Start with a word that shows the level of risk. Write "Warning" for a risk to
  persons. Write "Caution" for a risk to data or equipment.
- **7.2** Then give a clear command or condition.
- **7.3** Then give the risk or the possible result.

For example: "Caution: Do not force push to a shared branch. A force push can erase the
commits of other persons."

#### Punctuation and word count (STE section 8)

- **8.1** Do not use the semicolon. Write two sentences.
- **8.2** Use a hyphen to join words that are directly related, for example "read-only".
- **8.3** Use parentheses for references, identifiers, abbreviations, short explanations,
  and alternatives.
- **8.4** In a vertical list, a colon ends a sentence for the word count.
- **8.5 to 8.7** For the word count, count each of these items as one word:
  - Text in parentheses.
  - A number, or a number with its unit.
  - An abbreviation or an identifier.
  - Quoted text.
  - A title or a heading.
  - A proper noun.
  - A hyphenated word.

#### Writing practices (STE section 9)

- **9.1** If you cannot replace a word with an approved word, write the sentence again
  with a different structure.
- **9.2** Use each word correctly.
- **9.3** Do not use phrasal verbs. For example, write "prepare" or "configure", not "set
  up". Write "find", not "find out".
- **9.4** Use the same terms and the same style in all of the text.

#### General recommendations (STE)

- **GR-1** Write "that" after verbs such as "make sure", "show", and "recommend". For
  example: "Make sure that the tests pass."
- **GR-2** When you use "with", read the sentence again. Make sure that the sentence has
  only one meaning.
- **GR-3, GR-4** If a pronoun can refer to more than one noun, write the noun. The
  local-references rule in Part 2 makes this rule stricter.
- **GR-6** Do not use Latin abbreviations. Write "for example", not "e.g.". Write "that
  is", not "i.e.". Do not write "etc.".
- **GR-7** Use gender-neutral language. Use "they" for a person whose pronouns you do not
  know.
- **GR-8** Use the possessive form, for example "the user's file", only when you are sure
  that it is correct.

### Part 2: Two more rules

These two rules apply together with the STE rules.

#### The local-references rule

The reader must not look back far to find what a word refers to.

- A pronoun ("it", "they", "this", "that", "these", "those") must refer to a noun in the
  same paragraph. A short noun, for example "the file" or "the change", must also refer
  to a noun in the same paragraph.
- Only one noun in that paragraph can match the reference. If two nouns can match, write
  the full noun.
- At the start of a paragraph, a list item, a table cell, or a reply, write the full noun.
  Do not use "It", "This", or "They" to refer to an earlier paragraph.
- A heading does not give a noun to the text below the heading. Under the heading
  "OutboxAccess", do not start with "It stores". Write "OutboxAccess stores".
- In a conversation, each reply must make sense alone. Do not write "the PR" or "the
  second option" to refer to an earlier reply. Write the name or the full description.

For example, do not write: "The run found a problem in the template and in the checker.
It is now correct." Write: "The run found a problem in the template and in the checker. I
corrected the template."

#### The described-IDs rule

An ID is a short code that names an item, for example "B2", "R3", "V1", "UC2", "PR #6",
"task #4", or a commit hash. An ID without a description makes the reader look back.

- Each time that you write an ID, write a short description of the item in the same
  sentence. For example: "B2 (cache the results)".
- When the reader must select an alternative, give each alternative its ID and its
  description in the question. Do not ask "B1, B2, or B3?".
- In a table, a row that gives the ID and the description is sufficient for that row.
- A header field, for example `Intent: IN-0001`, holds only the ID. Do not add a
  description to the ID there.
- Make each description short and simple: two to eight words.
- If the ID is not necessary for the reader, do not use the ID. Use the description only.

For example, do not write: "Do you want B1 or B3?" Write: "Do you want B1 (keep the
cache) or B3 (remove the cache)?"

### Part 3: How to apply the rules

#### Replies to the user

- Give the answer or the result first. Then give the details.
- Use plain words, and give the context that the reader must have.
- Use short sentences. Use a list for three or more items. Do not write a paragraph when
  sentences in a list are sufficient.
- Write only about the topic. Do not add text that does not relate to the topic.
- Make each reply clear alone. Obey the local-references rule.
- When you ask a question with alternatives, obey the described-IDs rule.

#### Skills, agent definitions, and prompts

- If a skill gives an exact output format, the format has priority over these
  guidelines. For example, a skill can tell an agent to write one sentence for each
  option. Then the agent writes one sentence, also when the sentence has two topics.
- Write each step in the imperative. Write one instruction in each sentence.
- Put the condition first: "If the suite exists, load the suite."
- Give numbers to the steps of a procedure.
- Write the purpose of a skill, and other descriptive text, with the descriptive rules.
- In the `description` of a skill, keep the name and the trigger phrases of the skill.
  Do not change these quoted phrases. Write the other text of the description with the
  rules.
- A prompt for a different agent must make sense alone, because that agent does not see
  your conversation.

#### Documents and artifacts

- Start each section with its primary point.
- Use headings as key words.
- Give each technical noun that a reader possibly does not know in a "Words used here"
  list. Use one line for each word.
- Use a table to compare items. Use a list for steps and alternatives.

#### Commit messages and pull requests

- Write the subject line of a commit in the imperative, for example "Add the linter".
- Write the body as descriptive text.

### Part 4: Examine your text

1. Run the linter: `python check_writing.py FILE`. The linter is in the `scripts` folder of
   the `improve-writing` skill. The linter finds the problems that a script can measure.
2. To examine words against the STE dictionary, get the standard. The standard is free
   from <https://www.asd-ste100.org>. Then give the linter your copy:
   `--dictionary PATH`. The path can be the PDF file or a text file of the PDF.
3. Read the text again for the rules that a script cannot measure. Examples are one topic
   in each sentence, the local-references rule, and accurate facts.

The `/improve-writing` skill does these three steps and writes the text again.

### Source

- ASD-STE100 Simplified Technical English, Issue 9, 2025-01-15, by ASD (the Aerospace,
  Security and Defence Industries Association of Europe). Part 1 gives the rules of the
  standard in short form, with the rule numbers of the standard.
- The standard is free from <https://www.asd-ste100.org>. ASD does not let other persons
  distribute the standard. Thus, this file does not contain the text of the standard or
  its dictionary.
- ASD-STE100 is a registered trademark of ASD.
````

### DES-pdlc-check-tagging

````
# DES-pdlc-check-tagging · How checks name their requirement

Status: agreed · Default: yes · Ask at init: yes

## Rule

The requirement ID starts the name of the check, for example `CAP-email.R3 sends from a
template`. A check that proves two requirements names the two requirements.

If the check runner does not accept `.` or `-` in names (Python's `unittest`, for
example), write the ID with underscores instead: `test_CAP_email_R3_sends_from_a_template`.
The two forms count as the same ID. Use only one form in each project.

Lay checks out the same way everywhere:

- Put new check files in the check folder (`tests/` in a project that had none). Name
  each file after the spec it proves, in a form the runner finds: `test_CAP_email.py`,
  `CAP-email.test.js`.
- Inside a file, make one group per requirement (a test class or a `describe` block).
  Name the group with the requirement ID: `class CAP_email_R3(unittest.TestCase)`,
  `describe("CAP-email.R3", ...)`.
- Each check's name still starts with the ID, then says what it proves.

The acceptance checks of an intent go in one file for each intent, at the path of
"acceptance file" in `pdlc/config.md`. The name of the file holds the word "acceptance"
and the intent ID, for example `tests/acceptance_IN_0012.py` or
`acceptance/IN-0012.acceptance.js`. The "all" command does not run such a file. Inside the
file, make one group for each requirement, and start each check name with the requirement
ID.

## Why

The trace from a requirement to its checks is only as good as this naming. Thus, the
naming must be simple and the same everywhere.
````

### DES-lean-checks

````
# DES-lean-checks · How a Lean check file runs and reports

Status: agreed · Default: no

## Rule

Each check file is a Lean script that `lake env lean --run <file> [filter]` runs. The file
has these parts:

- One file for each spec, named after the spec: `tests/CAP-scenario.lean`. The acceptance
  file of an intent is `tests/acceptance/IN-0001.acceptance.lean`.
- The imports of the library modules that the file calls, for example
  `import StoragePolicySim.Scenario`. A check file does not import another check file.
  Thus, each file holds its own small helpers.
- `def main (args : List String) : IO UInt32`.
- Each check has a name that starts with its requirement ID and a space, for example
  `"CAP-scenario.R1 day 171 gives more than twice day 354"`.
- The checks of one requirement are together, under the comment `-- CAP-scenario.R1`.

When `main` gets a first argument, it runs only the checks whose names start with that
argument and a space. Thus, the filter `CAP-scenario.R1` does not run `CAP-scenario.R10`.

The file prints `FAIL <name>: <what went wrong>` for each failed check. Its last line is
`<n> checks, <k> failed`. It exits with 1 when `k` is more than 0, and else with 0. A
filter that matches no check gives `0 checks, 0 failed`. The checks port reads that line
as "no checks found".

A check that runs the `sim` command uses `IO.Process.output` with the command `timeout`
and the arguments `60`, `.lake/build/bin/sim`, and then the arguments of `sim`. The check
reads the exit code, stdout and stderr. A `Float` comparison uses a tolerance.

## Example

```lean
import StoragePolicySim.Scenario
open StoragePolicySim

structure Check where
  name : String
  run : IO (Option String)   -- none: pass, some msg: fail

def checks : List Check := [
  -- CAP-scenario.R1
  { name := "CAP-scenario.R1 night gives no output",
    run := do
      let v := pvOutput site45 171 0 .sunny
      return if v == 0 then none else some s!"got {v}" }
]

def main (args : List String) : IO UInt32 := do
  let sel := match args with
    | f :: _ => checks.filter (fun (c : Check) => c.name.startsWith (f ++ " "))
    | [] => checks
  let mut failed := 0
  for c in sel do
    match ← c.run with
    | none => pure ()
    | some msg => failed := failed + 1; IO.println s!"FAIL {c.name}: {msg}"
  IO.println s!"{sel.length} checks, {failed} failed"
  return if failed > 0 then 1 else 0
```

The toolchain is Lean 4.35.0. In this version, `String.trim` does not exist. Use
`String.trimAscii` and then `.toString`, or split with `String.splitOn`.

## Why

Lean has no standard check runner. One small form for every file gives each check a name
with its requirement ID. It also gives a filter for one requirement, and one count line for the checks
port.
````

## The code

### Diff against pdlc/CH-0001-scenario

````
diff --git a/StoragePolicySim/Strategy.lean b/StoragePolicySim/Strategy.lean
new file mode 100644
index 0000000..f2b426e
--- /dev/null
+++ b/StoragePolicySim/Strategy.lean
@@ -0,0 +1,88 @@
+/-
+The strategies that the simulation compares. For each hour, a strategy asks the battery to
+charge or to discharge. For each day, a strategy also places the flexible load.
+CAP-strategies (battery and load strategies) gives the rules.
+-/
+namespace StoragePolicySim
+
+/-- A named strategy for the battery and the flexible load. -/
+inductive Strategy
+  /-- No battery use. -/
+  | none
+  /-- Battery use at any hour. -/
+  | greedy
+  /-- Discharge only in the evening. -/
+  | evening
+  /-- Greedy battery use, and the flexible load in the sunniest hours. -/
+  | shift
+  deriving BEq, Repr, Inhabited
+
+/-- What a strategy asks the battery to do for one hour. -/
+structure Request where
+  /-- The energy that the strategy asks to charge. -/
+  chargeKwh : Float
+  /-- The energy that the strategy asks to discharge. -/
+  dischargeKwh : Float
+  deriving Repr
+
+/-- The strategies, in the order of the comparison. -/
+def Strategy.all : List Strategy :=
+  [Strategy.none, Strategy.greedy, Strategy.evening, Strategy.shift]
+
+/-- The name of a strategy on the command line. -/
+def Strategy.name : Strategy → String
+  | .none => "none"
+  | .greedy => "greedy"
+  | .evening => "evening"
+  | .shift => "shift"
+
+/-- The strategy whose name matches `name` exactly, or `Option.none`. -/
+def Strategy.ofName? (name : String) : Option Strategy :=
+  Strategy.all.find? (fun s => s.name == name)
+
+/-- The first hour of the evening. The evening is 17:00 to 23:59. -/
+private def eveningStartHour : Nat := 17
+
+/-- The number of hours that get the flexible load of the `shift` strategy. -/
+private def sunniestHourCount : Nat := 3
+
+/-- A request that charges with the full surplus and discharges for the full shortfall. -/
+private def fullRequest (surplusKwh shortfallKwh : Float) : Request :=
+  { chargeKwh := surplusKwh, dischargeKwh := shortfallKwh }
+
+/-- The request of a strategy for one hour. The simulation applies the limits of the
+battery. -/
+def Strategy.decide (s : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request :=
+  match s with
+  | .none => { chargeKwh := 0, dischargeKwh := 0 }
+  | .greedy | .shift => fullRequest surplusKwh shortfallKwh
+  | .evening =>
+    let dischargeKwh := if hour ≥ eveningStartHour then shortfallKwh else 0
+    { chargeKwh := surplusKwh, dischargeKwh := dischargeKwh }
+
+/-- The hours of a day, from the most solar energy to the least. A tie goes to the earlier
+hour. -/
+private def hoursBySun (pvKwh : Array Float) : List Nat :=
+  let comesFirst (a b : Nat) : Bool :=
+    pvKwh[a]! > pvKwh[b]! || (pvKwh[a]! == pvKwh[b]! && a ≤ b)
+  (List.range pvKwh.size).mergeSort comesFirst
+
+/-- The flexible load of the `shift` strategy: equal parts in the sunniest hours. A day
+with no solar energy keeps the flexible load at its default hours. -/
+private def shiftIntoSun (pvKwh flexKwh : Array Float) : Array Float :=
+  if pvKwh.all (· ≤ 0) then flexKwh
+  else
+    let totalFlexKwh := flexKwh.foldl (· + ·) 0
+    let sunniestHours := (hoursBySun pvKwh).take sunniestHourCount
+    let partKwh := totalFlexKwh / sunniestHourCount.toFloat
+    (List.range flexKwh.size).toArray.map (fun h =>
+      if sunniestHours.contains h then partKwh else 0)
+
+/-- The flexible load of each hour of a day, after the strategy places it. `pvKwh` is the
+solar energy of each hour, and `flexKwh` is the flexible load at its default hours. -/
+def Strategy.placeFlex (s : Strategy) (pvKwh flexKwh : Array Float) : Array Float :=
+  match s with
+  | .none | .greedy | .evening => flexKwh
+  | .shift => shiftIntoSun pvKwh flexKwh
+
+end StoragePolicySim
````

### StoragePolicySim/Strategy.lean

````
/-
The strategies that the simulation compares. For each hour, a strategy asks the battery to
charge or to discharge. For each day, a strategy also places the flexible load.
CAP-strategies (battery and load strategies) gives the rules.
-/
namespace StoragePolicySim

/-- A named strategy for the battery and the flexible load. -/
inductive Strategy
  /-- No battery use. -/
  | none
  /-- Battery use at any hour. -/
  | greedy
  /-- Discharge only in the evening. -/
  | evening
  /-- Greedy battery use, and the flexible load in the sunniest hours. -/
  | shift
  deriving BEq, Repr, Inhabited

/-- What a strategy asks the battery to do for one hour. -/
structure Request where
  /-- The energy that the strategy asks to charge. -/
  chargeKwh : Float
  /-- The energy that the strategy asks to discharge. -/
  dischargeKwh : Float
  deriving Repr

/-- The strategies, in the order of the comparison. -/
def Strategy.all : List Strategy :=
  [Strategy.none, Strategy.greedy, Strategy.evening, Strategy.shift]

/-- The name of a strategy on the command line. -/
def Strategy.name : Strategy → String
  | .none => "none"
  | .greedy => "greedy"
  | .evening => "evening"
  | .shift => "shift"

/-- The strategy whose name matches `name` exactly, or `Option.none`. -/
def Strategy.ofName? (name : String) : Option Strategy :=
  Strategy.all.find? (fun s => s.name == name)

/-- The first hour of the evening. The evening is 17:00 to 23:59. -/
private def eveningStartHour : Nat := 17

/-- The number of hours that get the flexible load of the `shift` strategy. -/
private def sunniestHourCount : Nat := 3

/-- A request that charges with the full surplus and discharges for the full shortfall. -/
private def fullRequest (surplusKwh shortfallKwh : Float) : Request :=
  { chargeKwh := surplusKwh, dischargeKwh := shortfallKwh }

/-- The request of a strategy for one hour. The simulation applies the limits of the
battery. -/
def Strategy.decide (s : Strategy) (hour : Nat) (surplusKwh shortfallKwh : Float) : Request :=
  match s with
  | .none => { chargeKwh := 0, dischargeKwh := 0 }
  | .greedy | .shift => fullRequest surplusKwh shortfallKwh
  | .evening =>
    let dischargeKwh := if hour ≥ eveningStartHour then shortfallKwh else 0
    { chargeKwh := surplusKwh, dischargeKwh := dischargeKwh }

/-- The hours of a day, from the most solar energy to the least. A tie goes to the earlier
hour. -/
private def hoursBySun (pvKwh : Array Float) : List Nat :=
  let comesFirst (a b : Nat) : Bool :=
    pvKwh[a]! > pvKwh[b]! || (pvKwh[a]! == pvKwh[b]! && a ≤ b)
  (List.range pvKwh.size).mergeSort comesFirst

/-- The flexible load of the `shift` strategy: equal parts in the sunniest hours. A day
with no solar energy keeps the flexible load at its default hours. -/
private def shiftIntoSun (pvKwh flexKwh : Array Float) : Array Float :=
  if pvKwh.all (· ≤ 0) then flexKwh
  else
    let totalFlexKwh := flexKwh.foldl (· + ·) 0
    let sunniestHours := (hoursBySun pvKwh).take sunniestHourCount
    let partKwh := totalFlexKwh / sunniestHourCount.toFloat
    (List.range flexKwh.size).toArray.map (fun h =>
      if sunniestHours.contains h then partKwh else 0)

/-- The flexible load of each hour of a day, after the strategy places it. `pvKwh` is the
solar energy of each hour, and `flexKwh` is the flexible load at its default hours. -/
def Strategy.placeFlex (s : Strategy) (pvKwh flexKwh : Array Float) : Array Float :=
  match s with
  | .none | .greedy | .evening => flexKwh
  | .shift => shiftIntoSun pvKwh flexKwh

end StoragePolicySim
````

## Writing check

`pdlc/bin/check_writing.py --since 8e9c0b3c9f38fc8845a17585a59e2012b6088332` on pdlc/changes/CH-0002-strategies/change.md, pdlc/specs/capabilities/CAP-strategies.md:

````
No findings.
````

