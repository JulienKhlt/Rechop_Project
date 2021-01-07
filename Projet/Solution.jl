include("code_Julia/graphe.jl")
include("code_Julia/dimensions.jl")
include("code_Julia/usine.jl")
include("code_Julia/fournisseur.jl")
include("code_Julia/emballage.jl") 
include("code_Julia/instance.jl")
include("code_Julia/route.jl")
include("code_Julia/solution.jl")
include("code_Julia/cost.jl")
include("code_Julia/feasibility.jl")
include("Resolution_PNLE.jl")
include("cluster.jl")
include("borne_inf.jl")
include("New_PNLE.jl")
include("clustering.jl")
include("remplissage_camion.jl")
include("first_try_meta.jl")

function solution(name_inst)
    instance = lire_instance(name_inst)
    usines = instance.usines
    fournisseurs = instance.fournisseurs
    emballages = instance.emballages
    L = instance.L
    J = instance.J

    Sol = creation_livraison(usines, fournisseurs, emballages, J, L)
    show(Sol)
    println(feasibility(Sol, instance))
    cost(Sol, instance, verbose=true)
end

function take(disponibility, fournisseurs, it, e, j)
    if (j==1)
        return disponibility >= fournisseurs[it].b⁻[e, j]-fournisseurs[it].s0[e]
    else
        return disponibility >= fournisseurs[it].b⁻[e, j]
    end
end

function association(usine, j, e, it, fournisseurs, number_of_e, su_i)
    association = []
    if (j == 1)
        disponibility = usine.s0[e] + usine.b⁺[e, j]
    else
        disponibility = usine.b⁺[e, j] + su_i
    end
    while(it <= length(fournisseurs) && take(disponibility, fournisseurs, it, e, j))
        number_of_truck = ceil(fournisseurs[it].b⁻[e, j]/number_of_e)
        if (number_of_truck > 0)
            push!(association, [fournisseurs[it], number_of_truck])
        end
        disponibility -= fournisseurs[it].b⁻[e, j+1]
        it += 1
    end
    return association, it, disponibility
end

function return_f(j, usines, fournisseurs, emballages, L, su)
    Sol = [] 
    for e in 1:length(emballages)
        E = []
        it = 1
        number_of_e = floor(L / emballages[e].l)
        
        for i in 1:length(usines)
            if (it <= length(fournisseurs)) 
                asso, it, su[e, i, j+1] = association(usines[i], j, e, it, fournisseurs, number_of_e, su[e, i, j])
                push!(E, [usines[i], asso])
            end
        end
        push!(Sol, E)
    end
    return Sol
end

function number_delivered(Sol, e, p, q, j)
    Q = zeros(Int, length(Sol))
    Q[e] = Sol[e][p][2][q][1].b⁻[e, j+1]
    return Q
end

function creation_stop(Sol, e, p, q, j)
    Q = number_delivered(Sol, e, p, q, j)
    stops = [RouteStop(f = Sol[e][p][2][q][1].f, Q = Q)] 
    return stops
end

function initialisation_stock_usines(E, U, J, su0)
    su = Array{Int,3}(undef, E, U, J)
    for e in 1:E, u in 1:U
        su[e, u, 1] =  su0[e, u]
    end
    return su
end

function creation_livraison(usines, fournisseurs, emballages, J, L)
    R = 0
    routes = Route[]
    su0 = collect(usines[u].s0[e] for e = 1:length(emballages), u = 1:length(usines))
    su = initialisation_stock_usines(length(emballages), length(usines), J, su0)
    # sf = Array{Int,3}(undef, E, F, J)
    for j in 1:J-1
        Sol = return_f(j, usines, fournisseurs, emballages, L, su)
        for e in 1:length(Sol)
            for p in 1:length(Sol[e])
                for q in 1:length(Sol[e][p][2])
                    stops = creation_stop(Sol, e, p, q, j)
                    push!(routes, Route(r = R+1, j = j, x = Sol[e][p][2][q][2], u = p, F = 1, stops = stops))
                    R += 1
                end
            end
        end
    end
    return Solution(R = R, routes = routes)
end

if abspath(PROGRAM_FILE) == @__FILE__
    filename = "Data/petite.csv"
    filepath = joinpath(@__DIR__, filename)
    ptins = lire_instance(filepath)
    K = 1
    n_d = new_d(ptins.graphe.d, 1:ptins.U, 1:ptins.F, ptins.U, ptins.F, ptins.U)
    # R = 1
    clu = Cluster(U = ptins.usines[1], fourns = ptins.fournisseurs)
    # s0_u, s0_f = stock_ini(ptins.usines, ptins.fournisseurs, 1:ptins.E, ptins.U, ptins.F)
    # R, routes, su_final, sf_final = PNLE_entier(ptins.usines, ptins.fournisseurs, ptins.emballages, ptins.J, ptins.U, ptins.F, ptins.E, 1:ptins.J, 1:ptins.U, 1:ptins.F, 1:ptins.E, ptins.E, K, ptins.L, ptins.γ, ptins.cstop, ptins.ccam, n_d, s0_u, s0_f)
    routes = opti_cluster(clu, ptins.emballages, ptins.J, 1:ptins.J, 1:ptins.E, ptins.U, K, ptins.L, ptins.γ, ptins.cstop, ptins.ccam, ptins.graphe.d)
    R =size(routes,1)
    # println(su_final)
    # println(sf_final)
    sol = Solution(R=R, routes=routes)
    show(sol)
    println(feasibility(sol, ptins))
    cost(sol, ptins, verbose=true)
    # ecrire_solution("test.txt", sol)

    # println(borne_inf(ptins))
    # solution(filepath)
    # Sol = lire_solution("test.txt")
    # show(Sol)
    # println(feasibility(Sol, ptins))
    # cost(Sol, ptins, verbose=true)
end