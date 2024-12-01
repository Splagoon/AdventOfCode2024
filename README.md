# Advent of Code 2024

## About

[Advent of Code](https://adventofcode.com/) is an annual programming puzzle challenge oragized by [Eric Wastl](http://was.tl/). Between December 1 and December 25 (Christmas), a new programming puzzle is posted daily. This repo contains my solutions for the [2024 puzzles](https://adventofcode.com/2024). I encourage everyone to solve the puzzles on their own before looking at my solutions.

## Running the Code

Puzzle solutions will be stored in the `lib/` folder as `XX.exs`, where `XX` is the date of the puzzle, `01` through `25`. Inputs will similarly be stored in the `data/` folder as `XX.txt`. To run the solutions, you must have [Elixir 1.17+](https://elixir-lang.org/install.html) installed.

Open the repo on the command line and first install the dependencies:

```sh
mix deps.get
```

Then run a solution with:

```sh
mix run lib/XX.exs
```

Where `XX` is the date of the puzzle, `01` through `25`.

All of the scripts should be platform-agnostic and run wherever Elixir is supported.
