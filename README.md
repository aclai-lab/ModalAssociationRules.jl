# ModalAssociationRules.jl

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aclai-lab.github.io/ModalAssociationRules.jl/) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aclai-lab.github.io/ModalAssociationRules.jl/dev)
[![Build Status](https://api.cirrus-ci.com/github/aclai-lab/ModalAssociationRules.jl.svg?branch=main)](https://cirrus-ci.com/github/aclai-lab/ModalAssociationRules.jl)
[![codecov](https://codecov.io/gh/aclai-lab/ModalAssociationRules.jl/branch/main/graph/badge.svg?token=LT9IYIYNFI)](https://codecov.io/gh/aclai-lab/ModalAssociationRules.jl)

Association rules in Julia!

## Compilation

This package is currently dependent on unregistered Julia packages. To compile the project, it is necessary to use the `dev` command of Pkg.jl, Julia's official package manager, targetting specific branch of [Sole](https://github.com/aclai-lab/Sole.jl) ecosystem.

The following instructions assume `~/.julia/dev/` as the only working directory.

    git clone https://github.com/aclai-lab/SoleBase.jl.git
    git clone https://github.com/aclai-lab/MultiData.jl.git
    git clone https://github.com/aclai-lab/SoleLogics.jl.git
    git clone https://github.com/aclai-lab/SoleData.jl.git
    git clone https://github.com/aclai-lab/SoleModels.jl.git
    git clone https://github.com/aclai-lab/ModalAssociationRules.jl.git

For each folder, checkout on `dev` branch and open the Julia REPL to install the dpendencies associated:

    SoleBase              -> ]instantiate
    MultiData             -> ]dev SoleBase
    SoleLogics            -> ]dev SoleBase
    SoleData              -> ]dev SoleBase SoleLogics MultiData
    SoleModels            -> ]dev SoleBase MultiData SoleLogics SoleData
    ModalAssociationRules -> ]dev SoleBase MultiData SoleLogics SoleData SoleModels

When not specified (every time but in SoleBase), also execute ```]instantiate```.