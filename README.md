# Causal Inference in Drug Discovery Short Course

This repository will contain lecture notes and example notebooks for the short course on causal inference in drug discovery during the [NOVAMATH Thematic Weeks 2024](https://eventos.fct.unl.pt/novamath_thematic_weeks/).

The example notebooks are written in [Julia][1], but should be easily translatable to other languages. [Julia][1] is an open-source programming language that combines the interactivity of [Python](https://www.python.org/), [R](https://www.r-project.org/) and [Matlab](https://mathworks.com), with the speed of [C](https://en.wikipedia.org/wiki/C_(programming_language)). Read more about its design principles and why it is good for scienticific applications, including computational biology here:

- [Why we created Julia](https://julialang.org/blog/2012/02/why-we-created-julia/)
- [Julia: come for the syntax, stay for the speed](https://www.nature.com/articles/d41586-019-02310-3)
- [Julia for biologists](https://www.nature.com/articles/s41592-023-01832-z)

[Julia][1] is also the language behind [PumasAI](https://pumas.ai/).

## Software installation

Follow the instructions on the [MIT Introduction to Computational Thinking course](https://computationalthinking.mit.edu/Fall23/installation/) to install [Julia][1] and [Pluto][3]. Optionally create an account on [JuliaHUb](https://juliahub.com/) if you want to explore a cloud-based [Julia][1] platform.

The repository code base uses [DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/) to make a reproducible scientific project named

> causal-inference-short-course

To (locally) reproduce this project, do the following:

1. Download this code base or [fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) the repository. Make sure to [sync your fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork) regularly to make sure it remains up-to-date! Notice that raw data are typically not included in the git-history and may need to be downloaded independently. 
2. Open a Julia console and do:
   ```
   julia> using Pkg
   julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`
   julia> Pkg.activate("path/to/this/project")
   julia> Pkg.instantiate()
   ```

This will install all necessary packages for you to be able to run the scripts and notebooks and
everything should work out of the box, including correctly finding local paths.

You may notice that most scripts and notebooks start with the commands:
```julia
using DrWatson
@quickactivate "causal-inference-short-course"
```
which auto-activate the project and enable local path handling from DrWatson.


[1]: https://julialang.org/
[2]: https://plutojl.org/
[3]: https://juliahub.com/
