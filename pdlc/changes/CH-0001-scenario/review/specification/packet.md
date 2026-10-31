# Review packet · CH-0001-scenario · specification

Judge only what is in this packet. Write your result next to it, in result.md.

Made at: 4c713c02812200de87d0a7841fe33ea7fb39b399

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
# CH-0001 · Seasonal sun, daily weather and household load

Intent: IN-0001 · Scope: CAP-scenario · Status: building · Ticket: none · Branch: pdlc/CH-0001-scenario · Base: main

Tests-Locked: 5de000a

## Delivers

The library gives the hours of a scenario. Each hour has a solar output from the season,
the sun height and a seeded daily sky. Each hour also has a base load and a flexible load.

## Requirements

### CAP-scenario.R1 · Seasonal sun

- Given latitude 45, when the sky is sunny at 12:00, then day 171 gives more than twice the output of day 354.
- Given latitude -41, when the sky is sunny at 12:00, then day 354 gives more than twice the output of day 171.
- Given latitude 0, when the sky is sunny at 12:00, then the outputs of day 171 and day 354 differ by less than 1%.
- Given latitude 45, when the sky is sunny at 00:00 on day 171, then the output is 0 kWh.
- Given latitude 45, when each hour of days 0 to 364 is sunny, then each output is from 0 to 5 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is cloudy, then the output is 0.5 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is overcast, then the output is 0.15 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 and 0 kW of panels, when the sky is sunny at 12:00 on day 171, then the output is 0 kWh.

### CAP-scenario.R2 · Daily weather

- Given seed 7 and latitude 45, when the scenario runs two times for 365 days, then the two runs give the same hours.
- Given latitude 45, when the scenario runs 365 days with seed 7 and with seed 8, then the skies differ on at least 50 days.
- Given seed 7 and 365 days, when the scenario runs, then it gives 8760 hours in order of day, then hour.
- Given seed 7 and 0 days, when the scenario runs, then it gives no hours.
- Given seed 7 and 365 days, when the scenario runs, then the 24 hours of each day have the same sky.
- Given seed 7 and 365 days, when the scenario runs, then each solar output equals R1 (seasonal sun) for its day, hour and sky. The tolerance is 0.000001 kWh.
- Given latitude 45, when seeds 1 to 20 run 365 days, then December to February has over twice the overcast days of June to August.
- Given latitude -41, when seeds 1 to 20 run 365 days, then June to August has over twice the overcast days of December to February.
- Given seed 7 and 365 days, when the scenario runs, then 60% or more of days 1 to 364 keep the previous sky.
- Given seed 7 and 730 days, when the scenario runs, then day 365 is day 0 of the year. Day 729 is day 364 of the year.

### CAP-scenario.R3 · Household load

- Given latitude 45, when the scenario runs 365 days, then the total load is 7300 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the scenario runs, then the base load of day 15 is 1.45 to 1.55 times the base load of day 197.
- Given latitude -41, when the scenario runs, then the base load of day 197 is 1.45 to 1.55 times the base load of day 15.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 19:00 is more than at 13:00.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 07:00 is more than at 03:00.
- Given 3 kWh of flexible load, when the scenario runs 365 days, then each day has 1 kWh of it at 18:00, 19:00 and 20:00. Each other hour has 0 kWh.
- Given 0 kWh of flexible load, when the scenario runs 365 days, then each hour has 0 kWh of flexible load.
- Given latitude 45, when seed 7 and seed 8 each run 365 days, then each hour has the same base and flexible load.

## Relies on

- DES-errors (conventions to follow)
- DES-writing-style (conventions to follow)
- DES-pdlc-check-tagging (conventions to follow)
- DES-lean-checks (conventions to follow)

## Interface

All entries are in the namespace `StoragePolicySim`, in `StoragePolicySim/Scenario.lean`. A
check imports `StoragePolicySim.Scenario` and opens `StoragePolicySim`. No entry can fail,
so no entry has an error code.

- `inductive Sky | sunny | cloudy | overcast` with `BEq`, `Repr` and `Inhabited` (assumed).
- `Sky.factor : Sky → Float`: 1.0 for `sunny`, 0.5 for `cloudy`, and 0.15 for `overcast`.
- `structure Site` with `Repr` and `Inhabited` (assumed). The fields are these:
  - `latitude : Float`: degrees, south is negative.
  - `pvKw : Float`: the kW of the panels.
  - `dailyLoadKwh : Float`: the load of a day, with the flexible load included.
  - `flexKwh : Float`: the part of the daily load that a strategy can move.
- `structure Hour` with `Repr` and `Inhabited` (assumed). The fields are these:
  - `day : Nat`: the day of the run, from 0.
  - `dayOfYear : Nat`: `day % 365`, from 0 (1 January) to 364.
  - `hour : Nat`: the hour of the day, from 0 to 23. Hour 12 is 12:00 to 13:00.
  - `sky : Sky`: the sky of the day.
  - `pvKwh : Float`: the solar energy of the hour.
  - `baseLoadKwh : Float`: the base load of the hour.
  - `flexKwh : Float`: the flexible load of the hour, at its default hours.
- `pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float` gives the solar energy
  of one hour in kWh. It reads only `latitude` and `pvKw` of the site.
- `scenario (site : Site) (seed days : Nat) : Array Hour` gives `24 × days` hours, in order of
  day, then hour. The same arguments give the same array.

### Test seams

- randomness: the `seed` argument of `scenario`. The same seed gives the same skies.
- clock: none, because no line depends on the real date or time.

## Files

- `StoragePolicySim/Scenario.lean`
- `lakefile.toml: the rest`
- `lean-toolchain`
- `lake-manifest.json`

## Check files

- `tests/CAP-scenario.lean`

## Steps

### Step 1 · Seasonal sun · [x]

- Requirement: CAP-scenario.R1
- Check: the checks named `CAP-scenario.R1 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

### Step 2 · Daily weather · [x]

- Requirement: CAP-scenario.R2
- Check: the checks named `CAP-scenario.R2 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

### Step 3 · Household load · [x]

- Requirement: CAP-scenario.R3
- Check: the checks named `CAP-scenario.R3 …` in `tests/CAP-scenario.lean`
- Done when: the checks pass

## Manual checks

none

## Progress log

- Planned as the first change of IN-0001 (solar self-consumption simulator), because each other change uses its hours.
- The builder found that `tests/CAP-scenario.lean` does not compile. `fun c => c.name` needs the type `Check` in Lean 4.35.0. The check goes back to the test writer, round 1 of 2.
- `lake build` writes `lake-manifest.json`. The file goes into "Files" (assumed), so that the build is the same each time.
- After the fix, the 34 checks of `tests/CAP-scenario.lean` pass on the code of the builder. App code exists after a send-back, so a pass is permitted.
- Build: the 34 checks of `tests/CAP-scenario.lean` pass. No check changed since the lock `5de000a`.
````

## The spec it covers: title and summary

````
# CAP-scenario · Hourly sun, weather and household load for a site

Status: active

## What it is for

CAP-scenario (sun, weather and load) makes the world that a strategy must deal with, one hour at a time. It gives
the solar output of each hour from the season and the sun height, and a daily sky from a
seeded weather model. It also gives the household load of each hour, with a seasonal base
load and a flexible load that a strategy can move.

## Code map

- `StoragePolicySim/Scenario.lean`
- `lakefile.toml: the rest`
- `lean-toolchain`
- `lake-manifest.json`
````

## The requirements, in full

### CAP-scenario.R1 · Seasonal sun

Status: built · Intents: IN-0001

The output of an hour is the panel power, times the sine of the sun height, times the sky
factor (assumed). The sun height uses the latitude, the day of the year, and the middle of
the hour in solar time (assumed).

The declination is 23.44 degrees times sin(2π × (285 + day) / 365), where day 0 is 1 January
(assumed). The sky factor is 1.0 for sunny, 0.5 for cloudy, and 0.15 for overcast (assumed).
When the sun is below the horizon, the output is 0. In these lines, the site has 5 kW of panels,
unless the line says otherwise.

- Given latitude 45, when the sky is sunny at 12:00, then day 171 gives more than twice the output of day 354.
- Given latitude -41, when the sky is sunny at 12:00, then day 354 gives more than twice the output of day 171.
- Given latitude 0, when the sky is sunny at 12:00, then the outputs of day 171 and day 354 differ by less than 1%.
- Given latitude 45, when the sky is sunny at 00:00 on day 171, then the output is 0 kWh.
- Given latitude 45, when each hour of days 0 to 364 is sunny, then each output is from 0 to 5 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is cloudy, then the output is 0.5 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 at 12:00 on day 171, when the sky is overcast, then the output is 0.15 times the sunny output. The tolerance is 0.001 kWh.
- Given latitude 45 and 0 kW of panels, when the sky is sunny at 12:00 on day 171, then the output is 0 kWh.

### CAP-scenario.R2 · Daily weather

Status: built · Intents: IN-0001

A seed and a number of days give one sky for each day, and the same hours each time. The
scenario starts on 1 January and gives the hours in order of day, then hour.

Each day keeps the sky of the day before with a chance of 0.6 (assumed). Else, the day takes
a new sky from the chances of its half of the year (assumed):

- Summer half: sunny 0.55, cloudy 0.30, overcast 0.15 (assumed).
- Winter half: sunny 0.20, cloudy 0.35, overcast 0.45 (assumed).

The summer half is days 90 to 272 of each year at latitude 0 or more, and the other days at
a negative latitude (assumed). After day 364, the day of the year starts again at 0.

- Given seed 7 and latitude 45, when the scenario runs two times for 365 days, then the two runs give the same hours.
- Given latitude 45, when the scenario runs 365 days with seed 7 and with seed 8, then the skies differ on at least 50 days.
- Given seed 7 and 365 days, when the scenario runs, then it gives 8760 hours in order of day, then hour.
- Given seed 7 and 0 days, when the scenario runs, then it gives no hours.
- Given seed 7 and 365 days, when the scenario runs, then the 24 hours of each day have the same sky.
- Given seed 7 and 365 days, when the scenario runs, then each solar output equals R1 (seasonal sun) for its day, hour and sky. The tolerance is 0.000001 kWh.
- Given latitude 45, when seeds 1 to 20 run 365 days, then December to February has over twice the overcast days of June to August.
- Given latitude -41, when seeds 1 to 20 run 365 days, then June to August has over twice the overcast days of December to February.
- Given seed 7 and 365 days, when the scenario runs, then 60% or more of days 1 to 364 keep the previous sky.
- Given seed 7 and 730 days, when the scenario runs, then day 365 is day 0 of the year. Day 729 is day 364 of the year.

### CAP-scenario.R3 · Household load

Status: built · Intents: IN-0001

The daily load includes the flexible load. The base load is the daily load less the flexible
load, spread over the hours by a fixed profile (assumed).

The profile has a morning peak and an evening peak (assumed). A seasonal factor of
1 + 0.2 × cos(2π × (day - peak) / 365) scales the base load (assumed). The peak is day 15 at
latitude 0 or more, and day 197 at a negative latitude (assumed).

By default, the flexible load uses equal parts at 18:00, 19:00 and 20:00 (assumed). The load
does not depend on the seed. In these lines, the daily load is 20 kWh with 3 kWh flexible,
unless the line says otherwise.

- Given latitude 45, when the scenario runs 365 days, then the total load is 7300 kWh. The tolerance is 0.1 kWh.
- Given latitude 45, when the scenario runs, then the base load of day 15 is 1.45 to 1.55 times the base load of day 197.
- Given latitude -41, when the scenario runs, then the base load of day 197 is 1.45 to 1.55 times the base load of day 15.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 19:00 is more than at 13:00.
- Given latitude 45, when the scenario runs, then on day 100 the base load at 07:00 is more than at 03:00.
- Given 3 kWh of flexible load, when the scenario runs 365 days, then each day has 1 kWh of it at 18:00, 19:00 and 20:00. Each other hour has 0 kWh.
- Given 0 kWh of flexible load, when the scenario runs 365 days, then each hour has 0 kWh of flexible load.
- Given latitude 45, when seed 7 and seed 8 each run 365 days, then each hour has the same base and flexible load.

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

### Diff against main

````
diff --git a/StoragePolicySim/Scenario.lean b/StoragePolicySim/Scenario.lean
new file mode 100644
index 0000000..a3922c0
--- /dev/null
+++ b/StoragePolicySim/Scenario.lean
@@ -0,0 +1,162 @@
+/-
+The scenario of a site: the solar output, the daily sky and the household load of each hour.
+CAP-scenario (sun, weather and load) gives the rules.
+-/
+namespace StoragePolicySim
+
+/-- The sky of a day. -/
+inductive Sky
+  | sunny
+  | cloudy
+  | overcast
+  deriving BEq, Repr, Inhabited
+
+/-- The share of the sunny output that the sky lets through. -/
+def Sky.factor : Sky → Float
+  | .sunny => 1.0
+  | .cloudy => 0.5
+  | .overcast => 0.15
+
+/-- A site with its panels and its household load. -/
+structure Site where
+  /-- Degrees. South is negative. -/
+  latitude : Float
+  /-- The kW of the panels. -/
+  pvKw : Float
+  /-- The load of a day, with the flexible load included. -/
+  dailyLoadKwh : Float
+  /-- The part of the daily load that a strategy can move. -/
+  flexKwh : Float
+  deriving Repr, Inhabited
+
+/-- One hour of a scenario. -/
+structure Hour where
+  /-- The day of the run, from 0. -/
+  day : Nat
+  /-- `day % 365`, from 0 (1 January) to 364. -/
+  dayOfYear : Nat
+  /-- The hour of the day, from 0 to 23. Hour 12 is 12:00 to 13:00. -/
+  hour : Nat
+  /-- The sky of the day. -/
+  sky : Sky
+  /-- The solar energy of the hour. -/
+  pvKwh : Float
+  /-- The base load of the hour. -/
+  baseLoadKwh : Float
+  /-- The flexible load of the hour, at its default hours. -/
+  flexKwh : Float
+  deriving Repr, Inhabited
+
+def daysInYear : Nat := 365
+
+private def pi : Float := 3.141592653589793
+
+private def radians (deg : Float) : Float := deg * pi / 180
+
+/-- The declination of the sun in degrees. Day 0 is 1 January. -/
+private def declination (dayOfYear : Nat) : Float :=
+  23.44 * Float.sin (2 * pi * (285 + dayOfYear.toFloat) / daysInYear.toFloat)
+
+/-- The sine of the sun height at the middle of the hour, in solar time. -/
+private def sinSunHeight (latitude : Float) (dayOfYear hour : Nat) : Float :=
+  let lat := radians latitude
+  let dec := radians (declination dayOfYear)
+  let hourAngle := radians (15 * (hour.toFloat + 0.5 - 12))
+  Float.sin lat * Float.sin dec + Float.cos lat * Float.cos dec * Float.cos hourAngle
+
+/-- The solar energy of one hour in kWh. It reads only `latitude` and `pvKw` of the site. -/
+def pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float :=
+  let h := sinSunHeight site.latitude dayOfYear hour
+  if h ≤ 0 then 0 else site.pvKw * h * sky.factor
+
+/-! ## Weather -/
+
+/-- The state of the seeded random numbers (SplitMix64). -/
+private structure Rng where
+  state : UInt64
+
+/-- The next number from 0 to less than 1, and the next state. -/
+private def Rng.next (r : Rng) : Float × Rng :=
+  let s := r.state + 0x9E3779B97F4A7C15
+  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
+  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
+  let z := z ^^^ (z >>> 31)
+  ((z >>> 11).toFloat / 9007199254740992.0, ⟨s⟩)
+
+/-- The chance that a day keeps the sky of the day before. -/
+private def keepChance : Float := 0.6
+
+/-- True for a day in the summer half of the year at this latitude. -/
+private def inSummerHalf (latitude : Float) (dayOfYear : Nat) : Bool :=
+  let north := 90 ≤ dayOfYear && dayOfYear ≤ 272
+  if latitude ≥ 0 then north else !north
+
+/-- A new sky from the chances of the half of the year. -/
+private def newSky (summer : Bool) (u : Float) : Sky :=
+  let (sunny, cloudy) := if summer then (0.55, 0.30) else (0.20, 0.35)
+  if u < sunny then .sunny
+  else if u < sunny + cloudy then .cloudy
+  else .overcast
+
+/-- The sky of each day of the run. -/
+private def skies (latitude : Float) (seed days : Nat) : Array Sky := Id.run do
+  let mut rng : Rng := ⟨seed.toUInt64⟩
+  let mut out : Array Sky := Array.mkEmpty days
+  for d in [0:days] do
+    let (u, r) := rng.next
+    rng := r
+    match out.back? with
+    | some prev =>
+      if u < keepChance then
+        out := out.push prev
+        continue
+    | none => pure ()
+    let (v, r) := rng.next
+    rng := r
+    out := out.push (newSky (inSummerHalf latitude (d % daysInYear)) v)
+  return out
+
+/-! ## Load -/
+
+/-- The share of the base load of a day in each hour, in parts of 1000. The profile has a
+morning peak at 07:00 and an evening peak at 19:00. -/
+private def profile : Array Float :=
+  #[30, 22, 20, 20, 20, 25, 40, 55, 50, 40, 30, 30,
+    32, 30, 33, 30, 38, 55, 75, 85, 80, 65, 55, 40]
+
+/-- The day of the year with the most base load. -/
+private def peakDay (latitude : Float) : Nat := if latitude ≥ 0 then 15 else 197
+
+/-- The seasonal factor that scales the base load of a day. -/
+private def seasonalFactor (latitude : Float) (dayOfYear : Nat) : Float :=
+  let offset := dayOfYear.toFloat - (peakDay latitude).toFloat
+  1 + 0.2 * Float.cos (2 * pi * offset / daysInYear.toFloat)
+
+/-- The base load of one hour in kWh. -/
+private def baseLoad (site : Site) (dayOfYear hour : Nat) : Float :=
+  (site.dailyLoadKwh - site.flexKwh) * seasonalFactor site.latitude dayOfYear *
+    profile[hour]! / 1000
+
+/-- The flexible load of one hour at its default hours: equal parts at 18:00, 19:00 and 20:00. -/
+private def defaultFlex (site : Site) (hour : Nat) : Float :=
+  if hour == 18 || hour == 19 || hour == 20 then site.flexKwh / 3 else 0
+
+/-! ## Scenario -/
+
+/-- The `24 × days` hours of a run, in order of day, then hour. The same arguments give the
+same array. -/
+def scenario (site : Site) (seed days : Nat) : Array Hour := Id.run do
+  let sky := skies site.latitude seed days
+  let mut out : Array Hour := Array.mkEmpty (24 * days)
+  for d in [0:days] do
+    let doy := d % daysInYear
+    let s := sky[d]!
+    for h in [0:24] do
+      out := out.push {
+        day := d, dayOfYear := doy, hour := h, sky := s,
+        pvKwh := pvOutput site doy h s,
+        baseLoadKwh := baseLoad site doy h,
+        flexKwh := defaultFlex site h }
+  return out
+
+end StoragePolicySim
diff --git a/lake-manifest.json b/lake-manifest.json
new file mode 100644
index 0000000..e11e984
--- /dev/null
+++ b/lake-manifest.json
@@ -0,0 +1,6 @@
+{"version": "1.3.0",
+ "packagesDir": ".lake/packages",
+ "packages": [],
+ "name": "«storage-policy-sim»",
+ "lakeDir": ".lake",
+ "fixedToolchain": false}
diff --git a/lakefile.toml b/lakefile.toml
new file mode 100644
index 0000000..0a10da9
--- /dev/null
+++ b/lakefile.toml
@@ -0,0 +1,7 @@
+name = "storage-policy-sim"
+version = "0.1.0"
+defaultTargets = ["StoragePolicySim"]
+
+[[lean_lib]]
+name = "StoragePolicySim"
+globs = ["StoragePolicySim.+"]
diff --git a/lean-toolchain b/lean-toolchain
new file mode 100644
index 0000000..a6aff06
--- /dev/null
+++ b/lean-toolchain
@@ -0,0 +1 @@
+leanprover/lean4:v4.35.0
````

### StoragePolicySim/Scenario.lean

````
/-
The scenario of a site: the solar output, the daily sky and the household load of each hour.
CAP-scenario (sun, weather and load) gives the rules.
-/
namespace StoragePolicySim

/-- The sky of a day. -/
inductive Sky
  | sunny
  | cloudy
  | overcast
  deriving BEq, Repr, Inhabited

/-- The share of the sunny output that the sky lets through. -/
def Sky.factor : Sky → Float
  | .sunny => 1.0
  | .cloudy => 0.5
  | .overcast => 0.15

/-- A site with its panels and its household load. -/
structure Site where
  /-- Degrees. South is negative. -/
  latitude : Float
  /-- The kW of the panels. -/
  pvKw : Float
  /-- The load of a day, with the flexible load included. -/
  dailyLoadKwh : Float
  /-- The part of the daily load that a strategy can move. -/
  flexKwh : Float
  deriving Repr, Inhabited

/-- One hour of a scenario. -/
structure Hour where
  /-- The day of the run, from 0. -/
  day : Nat
  /-- `day % 365`, from 0 (1 January) to 364. -/
  dayOfYear : Nat
  /-- The hour of the day, from 0 to 23. Hour 12 is 12:00 to 13:00. -/
  hour : Nat
  /-- The sky of the day. -/
  sky : Sky
  /-- The solar energy of the hour. -/
  pvKwh : Float
  /-- The base load of the hour. -/
  baseLoadKwh : Float
  /-- The flexible load of the hour, at its default hours. -/
  flexKwh : Float
  deriving Repr, Inhabited

def daysInYear : Nat := 365

private def pi : Float := 3.141592653589793

private def radians (deg : Float) : Float := deg * pi / 180

/-- The declination of the sun in degrees. Day 0 is 1 January. -/
private def declination (dayOfYear : Nat) : Float :=
  23.44 * Float.sin (2 * pi * (285 + dayOfYear.toFloat) / daysInYear.toFloat)

/-- The sine of the sun height at the middle of the hour, in solar time. -/
private def sinSunHeight (latitude : Float) (dayOfYear hour : Nat) : Float :=
  let lat := radians latitude
  let dec := radians (declination dayOfYear)
  let hourAngle := radians (15 * (hour.toFloat + 0.5 - 12))
  Float.sin lat * Float.sin dec + Float.cos lat * Float.cos dec * Float.cos hourAngle

/-- The solar energy of one hour in kWh. It reads only `latitude` and `pvKw` of the site. -/
def pvOutput (site : Site) (dayOfYear hour : Nat) (sky : Sky) : Float :=
  let h := sinSunHeight site.latitude dayOfYear hour
  if h ≤ 0 then 0 else site.pvKw * h * sky.factor

/-! ## Weather -/

/-- The state of the seeded random numbers (SplitMix64). -/
private structure Rng where
  state : UInt64

/-- The next number from 0 to less than 1, and the next state. -/
private def Rng.next (r : Rng) : Float × Rng :=
  let s := r.state + 0x9E3779B97F4A7C15
  let z := (s ^^^ (s >>> 30)) * 0xBF58476D1CE4E5B9
  let z := (z ^^^ (z >>> 27)) * 0x94D049BB133111EB
  let z := z ^^^ (z >>> 31)
  ((z >>> 11).toFloat / 9007199254740992.0, ⟨s⟩)

/-- The chance that a day keeps the sky of the day before. -/
private def keepChance : Float := 0.6

/-- True for a day in the summer half of the year at this latitude. -/
private def inSummerHalf (latitude : Float) (dayOfYear : Nat) : Bool :=
  let north := 90 ≤ dayOfYear && dayOfYear ≤ 272
  if latitude ≥ 0 then north else !north

/-- A new sky from the chances of the half of the year. -/
private def newSky (summer : Bool) (u : Float) : Sky :=
  let (sunny, cloudy) := if summer then (0.55, 0.30) else (0.20, 0.35)
  if u < sunny then .sunny
  else if u < sunny + cloudy then .cloudy
  else .overcast

/-- The sky of each day of the run. -/
private def skies (latitude : Float) (seed days : Nat) : Array Sky := Id.run do
  let mut rng : Rng := ⟨seed.toUInt64⟩
  let mut out : Array Sky := Array.mkEmpty days
  for d in [0:days] do
    let (u, r) := rng.next
    rng := r
    match out.back? with
    | some prev =>
      if u < keepChance then
        out := out.push prev
        continue
    | none => pure ()
    let (v, r) := rng.next
    rng := r
    out := out.push (newSky (inSummerHalf latitude (d % daysInYear)) v)
  return out

/-! ## Load -/

/-- The share of the base load of a day in each hour, in parts of 1000. The profile has a
morning peak at 07:00 and an evening peak at 19:00. -/
private def profile : Array Float :=
  #[30, 22, 20, 20, 20, 25, 40, 55, 50, 40, 30, 30,
    32, 30, 33, 30, 38, 55, 75, 85, 80, 65, 55, 40]

/-- The day of the year with the most base load. -/
private def peakDay (latitude : Float) : Nat := if latitude ≥ 0 then 15 else 197

/-- The seasonal factor that scales the base load of a day. -/
private def seasonalFactor (latitude : Float) (dayOfYear : Nat) : Float :=
  let offset := dayOfYear.toFloat - (peakDay latitude).toFloat
  1 + 0.2 * Float.cos (2 * pi * offset / daysInYear.toFloat)

/-- The base load of one hour in kWh. -/
private def baseLoad (site : Site) (dayOfYear hour : Nat) : Float :=
  (site.dailyLoadKwh - site.flexKwh) * seasonalFactor site.latitude dayOfYear *
    profile[hour]! / 1000

/-- The flexible load of one hour at its default hours: equal parts at 18:00, 19:00 and 20:00. -/
private def defaultFlex (site : Site) (hour : Nat) : Float :=
  if hour == 18 || hour == 19 || hour == 20 then site.flexKwh / 3 else 0

/-! ## Scenario -/

/-- The `24 × days` hours of a run, in order of day, then hour. The same arguments give the
same array. -/
def scenario (site : Site) (seed days : Nat) : Array Hour := Id.run do
  let sky := skies site.latitude seed days
  let mut out : Array Hour := Array.mkEmpty (24 * days)
  for d in [0:days] do
    let doy := d % daysInYear
    let s := sky[d]!
    for h in [0:24] do
      out := out.push {
        day := d, dayOfYear := doy, hour := h, sky := s,
        pvKwh := pvOutput site doy h s,
        baseLoadKwh := baseLoad site doy h,
        flexKwh := defaultFlex site h }
  return out

end StoragePolicySim
````

### lake-manifest.json

````
{"version": "1.3.0",
 "packagesDir": ".lake/packages",
 "packages": [],
 "name": "«storage-policy-sim»",
 "lakeDir": ".lake",
 "fixedToolchain": false}
````

### lakefile.toml

````
name = "storage-policy-sim"
version = "0.1.0"
defaultTargets = ["StoragePolicySim"]

[[lean_lib]]
name = "StoragePolicySim"
globs = ["StoragePolicySim.+"]
````

### lean-toolchain

````
leanprover/lean4:v4.35.0
````

## Writing check

`pdlc/bin/check_writing.py --since main` on pdlc/changes/CH-0001-scenario/change.md, pdlc/specs/capabilities/CAP-scenario.md, pdlc/specs/design/DES-lean-checks.md, pdlc/specs/jobs/JOB-simulate.md:

````
No findings.
````

