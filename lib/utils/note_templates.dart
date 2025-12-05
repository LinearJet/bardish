class NoteTemplate {
  final String name;
  final String content;

  const NoteTemplate({required this.name, required this.content});
}

class NoteTemplates {
  static const List<NoteTemplate> all = [
    NoteTemplate(
      name: 'To-Do List',
      content: '''# To-Do List

- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
''',
    ),
    NoteTemplate(
      name: 'Meeting Notes',
      content: '''# Meeting Notes

**Date:** 
**Attendees:** 

## Agenda
1. 
2. 

## Discussion Points
- 

## Action Items
- [ ] 
''',
    ),
    NoteTemplate(
      name: 'Daily Journal',
      content: '''# Daily Journal
**Date:** 

## 3 Things I'm Grateful For
1. 
2. 
3. 

## What I Did Today
- 

## How I Felt
''',
    ),
    NoteTemplate(
      name: 'Project Plan',
      content: '''# Project Plan: [Project Name]

## Goal
Describe the main goal of the project.

## Milestones
- [ ] Phase 1:
- [ ] Phase 2:
- [ ] Phase 3:

## Resources Needed
- 
''',
    ),
    NoteTemplate(
      name: 'Shopping List',
      content: '''# Shopping List

## Groceries
- [ ] 
- [ ] 

## Household
- [ ] 

## Other
- [ ] 
''',
    ),
    NoteTemplate(
      name: 'Lecture Notes',
      content: '''# Lecture: [Topic]
**Date:** 
**Professor:** 

## Key Concepts
- 

## Detailed Notes


## Summary
''',
    ),
    NoteTemplate(
      name: 'Book Review',
      content: '''# Book Review: [Title]
**Author:** 
**Rating:** ⭐⭐⭐⭐⭐

## Summary
Brief summary of the book.

## Key Takeaways
- 

## Favorite Quotes
> "Quote here"
''',
    ),
    NoteTemplate(
      name: 'Recipe',
      content: '''# Recipe: [Name]

**Prep Time:** 
**Cook Time:** 
**Servings:** 

## Ingredients
- [ ] 
- [ ] 

## Instructions
1. 
2. 
3. 
''',
    ),
    NoteTemplate(
      name: 'Weekly Planner',
      content: '''# Weekly Planner

## Monday
- [ ] 

## Tuesday
- [ ] 

## Wednesday
- [ ] 

## Thursday
- [ ] 

## Friday
- [ ] 

## Weekend
- [ ] 
''',
    ),
    NoteTemplate(
      name: 'Brainstorming',
      content: '''# Brainstorming: [Topic]

## Ideas
- 
- 
- 

## Pros/Cons
| Pros | Cons |
|------|------|
|      |      |
''',
    ),
    NoteTemplate(
      name: 'Workout Plan',
      content: '''# Workout Plan

**Focus:** (e.g. Upper Body, Cardio)

## Warm-up
- 

## Exercises
1. [Exercise] - [Sets] x [Reps]
2. 
3. 

## Cool-down
- 
''',
    ),
    NoteTemplate(
      name: 'Travel Itinerary',
      content: '''# Trip to [Destination]
**Dates:** 

## Day 1
- [ ] Morning: 
- [ ] Afternoon: 
- [ ] Evening: 

## Day 2
- [ ] 

## Packing List
- [ ] Passport
- [ ] 
''',
    ),
    NoteTemplate(
      name: 'Monthly Goals',
      content: '''# Goals for [Month]

## Personal
- [ ] 

## Professional
- [ ] 

## Health
- [ ] 
''',
    ),
    NoteTemplate(
      name: 'Bug Report',
      content: '''# Bug Report

**Affected Version:** 
**OS/Browser:** 

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior


## Actual Behavior

''',
    ),
    NoteTemplate(
      name: 'Feature Request',
      content: '''# Feature Request

## Problem Statement
What problem are you trying to solve?

## Proposed Solution
Describe the solution you have in mind.

## Alternatives Considered
''',
    ),
    NoteTemplate(
      name: 'User Persona',
      content: '''# User Persona: [Name]

**Role:** 
**Age:** 

## Goals
- 
- 

## Frustrations
- 
- 

## Bio
Short bio...
''',
    ),
    NoteTemplate(
      name: 'SWOT Analysis',
      content: '''# SWOT Analysis

## Strengths
- 

## Weaknesses
- 

## Opportunities
- 

## Threats
- 
''',
    ),
    NoteTemplate(
      name: 'OKR Tracking',
      content: '''# OKRs (Objectives and Key Results)

## Objective 1: [Description]
- [ ] KR 1: 
- [ ] KR 2: 

## Objective 2: [Description]
- [ ] KR 1: 
- [ ] KR 2: 
''',
    ),
    NoteTemplate(
      name: '1-on-1 Meeting',
      content: '''# 1-on-1 with [Name]
**Date:** 

## Check-in
How are you feeling?

## Wins
- 

## Challenges / Blockers
- 

## Feedback
''',
    ),
    NoteTemplate(
      name: 'Habit Tracker',
      content: '''# Habit Tracker

| Habit | M | T | W | T | F | S | S |
|-------|---|---|---|---|---|---|---|
| Water | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Read  | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Walk  | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
''',
    ),
  ];
}
