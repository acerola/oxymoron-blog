---
title: "Generative AI Design Patterns"
date: 2026-11-10
description: "Notes on the Hanbit translation of Generative AI Design Patterns: how the 32 patterns are written, and how much of the book still holds."
layout: post
tags: [AI, LLM, design-patterns]
category: Book
lang: en
ref: generative-ai-design-patterns
---

I recently read the Korean edition from Hanbit Media, 『에이전트 시대의 AI 시스템 설계』, and wrote down a rough impression. The original title is Generative AI Design Patterns, and the original came out in October 2025. By publication date, the book is already a little old. The field moves so fast that knowledge from a few months ago goes stale quickly.

## What the book is

It collects problems that come up again and again when you build an LLM application, and writes them as 32 patterns. Each pattern follows the same order: state the problem, give a solution, show a working code example, then cover the trade-offs of that solution. This is the format the Gang of Four used to name object-oriented design. The book is also a companion to Machine Learning Design Patterns, which Lakshmanan co-wrote. Maybe because of the length, the individual patterns do not go very deep.

The Korean title puts "agents" in the name, but the book is not only about agents. The range is wide: how to control the style and format of output, RAG, evaluation and reliability, cost and latency, and safeguards.

## How to read it

Each pattern stands on its own, so you do not have to read the book from front to back. It works better as a reference: open the chapter for the problem in front of you. O'Reilly rates it intermediate to advanced. If you already know LLMs to some extent, it reads closer to an introductory book. The later chapters show examples that combine the patterns from earlier in the book.

A lot of the detail is old, but the broad shape of each pattern still seems widely used. Many of them still hold in real applications and in harness engineering, so reading it was a chance to pull scattered knowledge into one place.

## Overall

The recurring patterns in an AI system are organized clearly. They are not deep, and much of the information is old, so the book is fine for looking back over what you already know and a poor fit if you want to learn the subject in depth. Lately, outside foundational academic knowledge, books do not seem like a good way to learn this field.
