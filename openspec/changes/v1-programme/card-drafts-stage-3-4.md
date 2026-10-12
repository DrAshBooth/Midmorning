# Draft cards for stages 3 and 4: not signed off

Status: DRAFT. The clinical reviewer has not read these cards. Do not ship them.

This file holds draft bodies and oneThing sentences for the eight cards of stage 3, "Alternatives", and stage 4, "Problem solving". `content` gives their ids and titles in "The card catalogue". An agent wrote them on 12 October 2026, in the same way as decision 97 for the stage 1 and 2 cards.

The drafts are not in `Packages/Content/Resources/cards.json`. A card there changes the bundle hash, so it needs a new content version and a new `content-lock.json`. Ash sets the content version at the merge with `scripts/content-lock`. So the build changes add the cards:

- `mm-t31.15` adds the stage 3 cards in the 3.1 urge-toolkit build change.
- `mm-t33.16` adds the stage 4 cards in the 3.3 problem-solving build change.

Each of those changes copies the text below into `cards.json`, raises the content version, and ships under the "Draft" flag until the clinical reviewer signs off. `content` owns the flag in "Clinical sign-off per content version". The reviewer can rewrite the titles and the bodies, as "The card catalogue" states. An id never changes.

"stage3.after" is not retired. The scenario "A retired card" in `content` uses it only as an example of a later version. So stage 3 has four cards and stage 4 has four cards.

## Rules the drafts follow

- `content`: three to five cards a stage, at most 500 words a body, one oneThing sentence with one action, at most one in-app link, no image, no placeholder.
- `content` "Tone of every card" and `product-rules` "Tone of every string": matter-of-fact, no praise, no blame, no cheer, no medical words, a lapse is a lapse.
- `content` "The forbidden list": no word from the full list. "binge" appears only in "binge eat", "binge eating" and "a binge". No bare "binges". The control name "I binged" appears once, in quotation marks, as the app shows it.
- `content` "Plain UK English": UK spelling, "you", plain words.
- A check on 12 October 2026 ran the full forbidden list, the US spelling list, the "binge" rule, the bare "binges" rule and the word count over every draft. All passed. The clinical reviewer still checks tone and reading level.

## Notes for the clinical reviewer

1. Alternatives. The cards say a good alternative is active, at least a little pleasant, possible at the times urges come, and hard to do while eating. The examples list in `urge-toolkit` holds "Put music or a podcast on". A person can eat while they listen to music. Check whether that example stays.
2. Early urges. "stage3.urges" asks the person to act at the first sign of an urge. The app has no screen for this. The card carries it.
3. High-risk times. "stage3.after" and "stage3.list" ask the person to fit the list to the times urges come. The app has no feature to plan an alternative ahead of a known time. By ruling r23-07 (12 October 2026), the cards "Your alternatives list" and "After the urge" alone carry "plan an alternative ahead of a predictable high-risk time".
4. Review timing. "stage4.review" follows the spec: the reminder comes a week later, and the person can answer step 6 sooner. By ruling r23-04 (12 October 2026), the reminder comes on the seventh day after the first "Done" with text in step 5, at the "Weekly review time". The card text still fits that timing.
5. Practice. "stage4.steps" asks the person to use the worksheet early, when a problem is coming, and on small problems too.

## Stage 3, "Alternatives"

### stage3.urges: "Urges rise and pass"

Links: none.

Body:

> An urge to binge eat can feel as if it will keep getting stronger until you give in. It does not work like that. An urge rises, reaches a peak and then fades, like a wave. Most urges fade within about twenty minutes, even when you do nothing about them. Some take longer.
>
> Urges are easier to ride out when you catch them early. The first sign might be a thought about food that keeps coming back, feeling restless, or finding yourself in the kitchen without a reason. That is the moment to act, not when the urge is at its strongest.
>
> An urge is not a slip. Urges are a normal part of this stage, and each one that passes shows you that they do pass. You do not need to fight an urge or argue with it. You need something else to do while it peaks and fades.

One thing to do:

> The next time you notice an urge, tap Urge on Today straight away.

### stage3.list: "Your alternatives list"

Links: one, target "Alternatives list".

Body:

> Your alternatives list holds a few things you can do instead of eating when an urge comes. You write it now, while things are calm, so that you do not have to think of something in the moment. Open Alternatives list to write yours.
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
> You do not need to wait for the twenty minutes to end. When the urge has passed, tap "It passed". If a planned meal or snack is due, eat it and tap "I ate as planned". Eating a planned meal is not giving in. It is the plan doing its job.
>
> You can close the screen and come back to it. The timer keeps running, and Today shows when the urge started. If you prefer to breathe slowly or walk first, the exercise under the list is there for that.

One thing to do:

> Decide which item on your list you will try first at the next urge.

### stage3.after: "After the urge"

Links: none.

Body:

> Whatever happened, the next planned meal still happens on time.
>
> If the urge passed or you ate as planned, the app saves that and asks nothing more. If it was a binge, tap "I binged" and write the entry as you would any other. A binge during this stage is a lapse. It does not mean the list does not work, and it does not undo what came before.
>
> Later, at a calm moment, look back at what happened. Did you catch the urge early or late? Did the thing you chose fit the time and the place? Was there something on the list you could not do just then? Use what you notice to change the list. If urges keep coming at the same time of day, put something from your list into that time before the urge arrives.

One thing to do:

> Replace one item on your list with something you could do at the time your urges usually come.

## Stage 4, "Problem solving"

### stage4.patterns: "Patterns in the record"

Links: one, target "Problem solving".

Body:

> Starred entries and urges rarely come out of nowhere. Often the same things come before them: a time of day, a day of the week, a place, a long gap since you last ate, or a planned meal that did not happen.
>
> When the app finds something that comes up in more than half of your recent starred entries, or in more than half of your recent urges, it shows it as one plain sentence on the Problem solving screen, with the numbers filled in. The sentence is not a judgement. It is a place to start.
>
> You can also find a pattern yourself, and you do not need one from the app to start a worksheet. Look back at your last few starred entries and ask what was happening an hour or two before each one: where you were, who you were with, how you felt, and when you last ate.

One thing to do:

> Start a worksheet about what happened in the two hours before your last starred entry.

### stage4.steps: "Six steps"

Links: none.

Body:

> Problem solving is a skill, and it gets easier with practice. The worksheet takes you through six steps.
>
> First, say what the problem is, as exactly as you can. "Evenings" is hard to work on. "Evenings alone after a day with no lunch" is easier. If there are two problems, take one at a time. Second, list every option you can think of, even the unlikely ones, and do not judge them yet. Third, think through how each one would work out. Fourth, pick one, or a combination. Fifth, plan the steps: what, when and how. Sixth, look back at how it went.
>
> The best time to start is when you see a problem coming, not after it has led to a binge. Small, everyday problems are good practice too. The more often you use the steps, the quicker they come.

One thing to do:

> Start a worksheet for one problem you can see coming this week.

### stage4.pick: "Pick one and try it"

Links: none.

Body:

> In step 3 you think through each option: what would make it hard, what it would take, and whether you would really do it. No option needs to be perfect. In step 4, pick the one that seems most likely to work, or put two together.
>
> Then make it concrete in step 5. "Sort out lunch" is a hope. "Take lunch to work on Tuesday and Thursday, and eat it at 13:00" is a plan. Write down each step, when it happens and what you need for it.
>
> Then do it. If a step turns out to be harder than you thought, that is useful to know. It is not a failure of the plan or of you, and the next worksheet can use it.

One thing to do:

> Write the first step of your plan with a day and a time.

### stage4.review: "Look back a week later"

Links: none.

Body:

> A week after you finish the steps of a worksheet, the app reminds you to look back at it. You do not need to wait for the reminder. You can answer "How did it go?" as soon as you have tried the plan.
>
> Look at how you went about it, not only whether it worked. Was the problem clear enough? Did you think of enough options? Was the plan specific? Did you do the steps? If the plan did not work, the answer is often in one of those, and the next worksheet can use it.
>
> Keep the worksheets. A plan that worked once may help again. Problem solving stays open after this stage, so use it whenever a problem comes up.

One thing to do:

> Open your most recent worksheet and answer "How did it go?" for what you have done so far.
