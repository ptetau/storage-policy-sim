# Remit: specification

Default: no

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
- In this project, the writing rules (`DES-writing-style`, in the packet) are a guideline,
  not a hard rule. A break of a writing rule, or a finding under "Writing check", goes under
  "Notes" with its line and rule. It is not a problem, and it does not fail the review.
- A text that is wrong or unclear about what the code does is still a problem. Examples are
  a wrong fact, a wrong number, and a sentence with two possible meanings.
- On a re-review, the writing check covers only the lines that changed since the earlier
  review.
