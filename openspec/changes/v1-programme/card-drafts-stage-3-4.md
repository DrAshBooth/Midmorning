# Draft cards for stages 3 and 4: not signed off

Status: DRAFT. The clinical reviewer has not read these cards. Do not ship them.

This file holds draft bodies and oneThing sentences for the eight cards of stage 3, "Alternatives", and stage 4, "Problem solving". `content` gives their ids and titles in "The card catalogue". An agent wrote them on 12 October 2026, in the same way as decision 97 for the stage 1 and 2 cards. The review of stages 3 and 4 on 12 October 2026 changed them, as the notes below state. The round 24 rulings of 12 October 2026 changed "stage3.twenty", "stage3.after" and "stage4.patterns" again (notes 15 to 19).

The drafts are not in `Packages/Content/Resources/cards.json`. A card there changes the bundle hash, so it needs a new content version and a new `content-lock.json`. Ash sets the content version at the merge with `scripts/content-lock`. So the build changes add the cards:

- `mm-t31.15` adds the stage 3 cards in the 3.1 urge-toolkit build change.
- `mm-t33.16` adds the stage 4 cards in the 3.3 problem-solving build change.

Each of those changes copies the text below into `cards.json`, raises the content version, and ships under the "Draft" flag until the clinical reviewer signs off. `content` owns the flag in "Clinical sign-off per content version". The reviewer can rewrite the titles and the bodies, as "The card catalogue" states. An id never changes.

"stage3.after" is not retired. The scenario "A retired card" in `content` uses it only as an example of a later version. So stage 3 has four cards and stage 4 has four cards.

## Rules the drafts follow

- `content`: three to five cards a stage, at most 500 words a body, one oneThing sentence with one action, at most one in-app link, no image, no placeholder.
- `content` "Tone of every card" and `product-rules` "Tone of every string": matter-of-fact, no praise, no blame, no cheer, no medical words, a lapse is a lapse.
- `content` "The forbidden list": no word from the full list. "binge" appears only in "binge eat", "binge eating" and "a binge". No bare "binges". No card names the urge screen's control "I binged". "stage3.after" asks for the entry with the star on.
- No draft holds a link. Card links are not built yet (`content`, "One in-app link on a card"), and a person can read a card before its stage opens. So each card names a place in the app in words.
- `content` "Plain UK English": UK spelling, "you", plain words.
- A check on 12 October 2026 ran the full forbidden list, the US spelling list, the "binge" rule, the bare "binges" rule and the word count over every draft. All passed. The same check ran again on 12 October 2026 after the review changes, and all passed. It ran a third time on 12 October 2026 after the round 24 changes, also over the new strings of round 24, and all passed. The clinical reviewer still checks tone and reading level.

## Notes for the clinical reviewer

1. Alternatives. The cards say a good alternative is active, at least a little pleasant, possible at the times urges come, and hard to do while eating. The setup on the urge screen offers at least six examples that you sign off. The README of this change lists seven draft examples. Two of them are flagged: "Put music or a podcast on" and "Do a puzzle or a game". A person can eat while they listen to music or play a game on the phone, and "stage3.list" says that eating must not fit easily alongside an alternative. Keep, change or replace them. No draft example is for late evening at home, although the cards say that urges often come then.
2. Early urges. "stage3.urges" asks the person to act at the first sign of an urge. The app has no screen for this. The card carries it. The draft no longer says that urges fade "even when you do nothing about them", because that sentence works against the list two paragraphs later.
3. High-risk times. "stage3.after" and "stage3.list" ask the person to fit the list to the times urges come. The app has no feature to plan an alternative ahead of a known time. By ruling r23-07 (12 October 2026), the cards "Your alternatives list" and "After the urge" alone carry "plan an alternative ahead of a predictable high-risk time".
4. Review timing. "stage4.review" follows the spec. The reminder comes on the seventh day after the worksheet first closes with text in step 5, at the "Weekly review time" (ruling r23-04, 12 October 2026). The reminder has its own switch, so the card says that the app "can" remind. The person can answer step 6 sooner.
5. Practice. "stage4.steps" asks the person to use the worksheet early, when a problem is coming, and on small problems too. The draft no longer says "not after it has led to a binge", because a person who has just binged can read that as "you did it wrong".
6. Cards before their stage. A person can read every card from day 1, before its stage opens. So each one thing to do must make sense then too. Today, "stage3.urges" asks the person to tap Urge, and "stage3.list" asks for three items on the list. Neither exists before stage 3 opens.
7. The walk text. The urge screen's walk text says "walk" and "stand". Please make it work for a person who uses a wheelchair or cannot stand for long.
8. An urge to make up for eating. After a binge, the most likely urge is to make up for it: to be sick, to take laxatives, to skip the next planned meal or to exercise hard. The same steps help to ride out that urge. Please add one sentence that says so, to "stage3.urges" or "stage3.after". This fits ruling r1-01: the app has no field and no outcome for it.
9. The stage 3 question of the weekly review. The draft is "When an urge came, what did you do?" (ruling r23-05). It sits under the urge counts, and after a hard week it can read as a demand to account for a binge. Two other drafts are "What would you change on your alternatives list?", which points at the list, and "When an urge came, what did you try?". You write the text.
10. A crisis on the worksheet. The worksheet is the longest free-text screen, and the app never reads what the person writes. The worksheet now shows "Get support" in its navigation bar, and "stage4.steps" says that thoughts of hurting yourself need a person now. Please decide whether every worksheet also needs one fixed line under step 1 that says the same. That line is clearest when it is needed, but it adds a clinical line to every everyday worksheet.
11. The worksheet's guidance. The worksheet has two new draft lines: under step 1, "Think about what comes before it: a time, a place, a feeling or a long gap.", and under step 3, "For each one, ask: does it keep your planned meals and snacks in place?". "stage4.steps" and "stage4.pick" say the same two points. The app still never ranks or judges one option. Without these points, a person can plan a restriction, for example "Skip breakfast so I can eat later".
12. The pattern templates. The custom place template is now the draft "{n} of the {m} had the place {place}.", so that it reads correctly for any place, for example "In the car". The slot templates now say "on days with no entry beside {slot}", for example "on days with no entry beside Mid-afternoon" (ruling r24-09). They replace "{slot} didn't happen", which read badly with a label for a time of day. Please check both forms.
13. The stage 4 opening sentence. "The app can now show patterns from your record. The worksheet is ready." Its first sentence is false while "Pattern sentences" is off. Please reword it, or give a second form for that case.
14. "stage4.patterns" now says "since your last entry", not "since you last ate", because the gap is from the entry before. It also says that a pattern can come to Today once, as a card.
15. Times, not entries (ruling r24-05). A binge is often several entries. So the patterns now count the times the person starred an entry: starred entries of one record day that are less than 60 minutes apart count once. The templates now read "{n} of the {m} were after 20:00.", filled as "5 of the 7 times you starred an entry were after 20:00.". "stage4.patterns" now says "the times you starred an entry" and that entries less than an hour apart count as one time. The weekly review still counts starred entries.
16. A card with no numbers (ruling r24-02). The suggestion card on Today shows no number, for example "Most of the times you starred an entry lately were after 20:00." or "Most of your recent urges were after 20:00.". The Problem solving screen and the worksheet keep the numbers. "Most" must stay true when a group holds just over half of the total. "stage4.patterns" now says that the card on Today has no numbers. A card waits 12 hours after a starred entry or "I binged" (ruling r24-03). You can change that value.
17. Ideas on the urge screen (ruling r24-07). The urge screen now shows "Pick one and start it now." above the list. With an empty list, it shows your examples under "Ideas" as plain lines. So the examples also show at the moment of an urge, and a person sees them before the first visit to the setup. Please check that each example suits that moment, also late in the evening at home (note 1).
18. "I ate as planned" (ruling r24-08). After this outcome, the app opens a new entry with the time of the tap, so the person can write down the planned meal or snack. "stage3.twenty" and "stage3.after" now say so. "stage3.after" no longer says that the app asks nothing more after "I ate as planned".
19. The stage 4 rule (ruling r24-11). The Programme screen now shows "Opens after your first urge outcome, or after 7 recorded days. You have 2." "Urge outcome" is a word of the app, not a word that a person uses. Please reword the rule. The README of this change lists the rule strings.

## Stage 3, "Alternatives"

### stage3.urges: "Urges rise and pass"

Links: none.

Body:

> An urge to binge eat can feel as if it will keep getting stronger until you give in. It does not work like that. An urge rises, reaches a peak and then fades, like a wave. Most urges fade within about twenty minutes. Some take longer.
>
> Urges are easier to ride out when you catch them early. The first sign might be a thought about food that keeps coming back, feeling restless, or finding yourself in the kitchen without a reason. That is the moment to act, not when the urge is at its strongest.
>
> An urge is not a slip. Urges are a normal part of this stage, and each one that passes shows you that they do pass. You do not need to fight an urge or argue with it. You need something else to do while it peaks and fades.

One thing to do:

> The next time you notice an urge, tap Urge on Today straight away.

### stage3.list: "Your alternatives list"

Links: none.

Body:

> Your alternatives list holds a few things you can do instead of eating when an urge comes. You write it now, while things are calm, so that you do not have to think of something in the moment. When this stage opens, you find the list on the Programme screen: open Alternatives, then Alternatives list.
>
> A good alternative is something you do, not something you watch. It is something you can do at the times your urges tend to come, and something you find at least a little pleasant. It is hard to do while eating, and it often gets you out of the kitchen. A walk, a phone call, a shower or a small job with your hands are examples. Watching television and food shopping are not, because eating fits easily alongside them.
>
> Aim for four to six items. Include some you can do at home late in the evening, and some you can do when you are out. Change the list whenever an item does not help.

One thing to do:

> Add three things to your alternatives list today.

### stage3.twenty: "The twenty minutes"

Links: none.

Body:

> When you tap Urge, a timer starts and a wave shows the urge rising and fading. Under it is your list. Pick one thing and start it straight away. If the urge is still strong when you finish, pick another.
>
> You do not need to wait for the twenty minutes to end. When the urge has passed, tap "It passed". If a planned meal or snack is due, eat it and tap "I ate as planned". The app then opens a new entry, so you can write down what you ate. Eating a planned meal is not giving in. It is the plan doing its job.
>
> You can close the screen and come back to it. The timer keeps running, and Today shows when the urge started. If you prefer to breathe slowly or walk first, the exercise under the list is there for that.

One thing to do:

> Decide which item on your list you will try first at the next urge.

### stage3.after: "After the urge"

Links: none.

Body:

> Whatever happened, the next planned meal still happens on time.
>
> If the urge passed, the app saves that and asks nothing more. If you ate as planned, the app saves that and opens a new entry for what you ate. If it was a binge, write it as you would any other entry, with the star on. A binge during this stage is a lapse. It does not mean the list does not work, and it does not undo what came before.
>
> Later, at a calm moment, look back at what happened. Did you catch the urge early or late? Did the thing you chose fit the time and the place? Was there something on the list you could not do just then? Use what you notice to change the list. If urges keep coming at the same time of day, put something from your list into that time before the urge arrives.

One thing to do:

> Replace one item on your list with something you could do at the time your urges usually come.

## Stage 4, "Problem solving"

### stage4.patterns: "Patterns in the record"

Links: none.

Body:

> Starred entries and urges rarely come out of nowhere. Often the same things come before them: a time of day, a day of the week, a place, a long gap since your last entry, or a planned meal that did not happen.
>
> When the app finds something that comes up in more than half of the times you starred an entry lately, or in more than half of your recent urges, it shows it as one plain sentence on the Problem solving screen, with the numbers filled in. Starred entries less than an hour apart count as one time. The pattern can also come to Today once, as a card with no numbers. The sentence is not a judgement. It is a place to start.
>
> You can also find a pattern yourself, and you do not need one from the app to start a worksheet. Look back at your last few starred entries and ask what was happening an hour or two before each one: where you were, who you were with, how you felt, and when you last ate.

One thing to do:

> Start a worksheet about what happened in the two hours before your last starred entry.

### stage4.steps: "Six steps"

Links: none.

Body:

> Problem solving is a skill, and it gets easier with practice. The worksheet takes you through six steps.
>
> First, say what the problem is, as exactly as you can. "Evenings" is hard to work on. "Evenings alone after a day with no lunch" is easier. Think about what comes before the problem: a time, a place, a feeling or a long gap. If there are two problems, take one at a time. Second, list every option you can think of, even the unlikely ones, and do not judge them yet. Third, think through how each one would work out, and whether it keeps your planned meals and snacks in place. Fourth, pick one, or a combination. Fifth, plan the steps: what, when and how. Sixth, look back at how it went.
>
> It works best when you see a problem coming. After a hard day, it can also help you plan for the next one. Small, everyday problems are good practice too. The more often you use the steps, the quicker they come.
>
> The worksheet is for everyday problems. If you have thoughts of hurting yourself, talk to a person now, not to a worksheet. Tap "Get support" at the top of the worksheet or of Today.

One thing to do:

> Start a worksheet for one problem you can see coming this week.

### stage4.pick: "Pick one and try it"

Links: none.

Body:

> In step 3 you think through each option: what would make it hard, what it would take, and whether you would really do it. Ask too whether it keeps your planned meals and snacks in place. An option that skips or delays one can leave a long gap, and a long gap makes the next urge more likely. No option needs to be perfect. In step 4, pick the one that seems most likely to work, or put two together.
>
> Then make it concrete in step 5. "Sort out lunch" is a hope. "Take lunch to work on Tuesday and Thursday, and eat it at 13:00" is a plan. Write down each step, when it happens and what you need for it.
>
> Then do it. If a step turns out to be harder than you thought, that is useful to know. It is not a failure of the plan or of you, and the next worksheet can use it.

One thing to do:

> Write the first step of your plan with a day and a time.

### stage4.review: "Look back a week later"

Links: none.

Body:

> About a week after you write your plan, the app can remind you to look back at it. You do not need to wait for the reminder. You can answer "How did it go?" as soon as you have tried the plan.
>
> Look at how you went about it, not only whether it worked. Was the problem clear enough? Did you think of enough options? Was the plan specific? Did you do the steps? If the plan did not work, the answer is often in one of those, and the next worksheet can use it.
>
> Keep the worksheets. A plan that worked once may help again. Problem solving stays open after this stage, so use it whenever a problem comes up.

One thing to do:

> Answer "How did it go?" in your most recent worksheet.
