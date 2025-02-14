# ModalAssociationRules.jl

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aclai-lab.github.io/ModalAssociationRules.jl/) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aclai-lab.github.io/ModalAssociationRules.jl/dev)
[![Build Status](https://api.cirrus-ci.com/github/aclai-lab/ModalAssociationRules.jl.svg?branch=main)](https://cirrus-ci.com/github/aclai-lab/ModalAssociationRules.jl)
[![codecov](https://codecov.io/gh/aclai-lab/ModalAssociationRules.jl/branch/main/graph/badge.svg?token=LT9IYIYNFI)](https://codecov.io/gh/aclai-lab/ModalAssociationRules.jl)

Association rules in Julia!

## Compilation (development dependencies)

This package heavily depends on the [Sole](https://github.com/aclai-lab/Sole.jl) ecosystem.

To compile this package while referencing the `dev` branches of the other necessary Sole package, clone and instantiate them in a common folder, following the steps below.

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
