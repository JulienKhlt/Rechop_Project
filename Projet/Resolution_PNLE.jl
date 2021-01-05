include("code_Julia/route.jl")
using JuMP, Gurobi

function new_d(d, ind_U, ind_F, U, F, U0)
    n_d = spzeros(Int, U + F, U + F)
    for u in 1:(U)
        for f in 1:(U)
            n_d[u, f] = d[ind_U[u], ind_U[f]]
        end
        for f in 1:(F)
            n_d[u, f + U] = d[ind_U[u], ind_F[f] + U0]
        end
    end
    for u in 1:(F)
        for f in 1:(U)
            n_d[u+U, f] = d[ind_F[u] + U0, ind_U[f]]
        end
        for f in 1:(F)
            n_d[u+U, f+U] = d[ind_F[u] + U0, ind_F[f]+ U0]
        end
    end

    return n_d
end

function stock_ini(usines, fournisseurs, ind_E, U, F)
    # Stockage initial des usines, fournisseurs
    s0_u = collect(usines[u].s0[e] for e in ind_E, u in 1:U)
    s0_f = collect(fournisseurs[f].s0[e] for e in ind_E, f in 1:F)
    return s0_u, s0_f
end


function data(usines, fournisseurs, emballages, ind_E, U, F, ind_J, L)
    # Quantité reçue par les usines
    b⁺ = collect(usines[u].b⁺[e, j] for e in ind_E, u in 1:U, j in ind_J)
    
    # Quantité dont ont besoin les usines
    b⁻ = collect(fournisseurs[f].b⁻[e, j] for e in ind_E, f in 1:F, j in ind_J)
    
    # limites de stocks des usines, fournisseurs
    r_u = collect(usines[u].r[e, j] for e in ind_E, u in 1:U, j in ind_J)
    r_f = collect(fournisseurs[f].r[e, j] for e in ind_E, f in 1:F, j in ind_J)
    
    # cout de stockage excédentaire
    cs_u = collect(usines[u].cs[e] for e in ind_E, u in 1:U)
    cs_f = collect(fournisseurs[f].cs[e] for e in ind_E, f in 1:F)

    # cout d'envoi des cartons
    cexc = collect(fournisseurs[f].cexc[e] for e in ind_E, f in 1:F)
    
    # longueur des emballages
    l_e = collect(emballages[e].l for e in ind_E)
    
    # maximum d'emballages e que l'on peut mettre dans un camion
    number_of_e = []
    for e in ind_E
        push!(number_of_e, ceil(L/l_e[e]))
    end
    return b⁺, b⁻, r_u, r_f, cs_u, cs_f, cexc, l_e, number_of_e
end




function PNLE_entier(usines, fournisseurs, emballages, J, U, F, E, ind_J, ind_U, ind_F, ind_E, E0, K, L, γ, CStop, CCam, d, s0_u, s0_f, notrelaxed = true)
    # On résout le PNLE avec K camions disponibles par jour de manière optimale
    
    # On récupère les données liées à notre instance ou cluster
    b⁺, b⁻, r_u, r_f, cs_u, cs_f, cexc, l_e, number_of_e = data(usines, fournisseurs, emballages, ind_E, U, F, ind_J, L)

    # On calcule une borne sup du nombre d'emballages que l'on peut mettre dans un camion
    M = maximum(number_of_e)
    model = Model(optimizer_with_attributes(Gurobi.Optimizer,"TimeLimit"=>300,"OutputFlag"=>1))
    @variable(model, q[1:J, 1:K, 1:U+F, 1:U+F, 1:E] >= 0, integer = notrelaxed)
    # Les variables binéaires qui indiquent si l'arrête (i,j) est empruntée
    @variable(model, x[1:J, 1:K, 1:U+F, 1:U+F], Bin)
    # Les variables binéaires qui indiquent si le camion part de l'usine u ou pas
    @variable(model, x_u[1:J, 1:K, 1:U], Bin)


    # Le stockage dans les fournisseurs, usines
    @variable(model, sf[1:E, 1:F, 1:J] >= 0, integer = notrelaxed)
    @variable(model, su[1:E, 1:U, 1:J] >= 0, integer = notrelaxed)

    # Les quantités qui quittent l'usine u, et celle par camion
    @variable(model, z⁻[1:E, 1:U, 1:J] >= 0)
    @variable(model, z⁻k[1:E, 1:U, 1:J, 1:K] >= 0)

    # Les quantités qui entre dans un fournisseurs
    @variable(model, z⁺[1:E, 1:F, 1:J] >= 0)

    # Le max dans le stock des fournisseurs, neg est la quantité que l'on doit envoyées en utilisant des cartons
    @variable(model, new_sf[1:E, 1:F, 1:J] >= 0)
    @variable(model, pos[1:E, 1:F, 1:J] >= 0)
    @variable(model, neg[1:E, 1:F, 1:J] >= 0)

    # Le max des stocks
    @variable(model, cost_su[1:E, 1:U, 1:J] >= 0)
    @variable(model, cost_sf[1:E, 1:F, 1:J] >= 0)

    # Calcul du max du stock des fournisseurs
    @constraint(model, [e in 1:E, f in 1:F, j in 2:J], pos[e, f, j] == (sf[e, f, j-1] - b⁻[e, f, j]) + neg[e, f, j])
    @constraint(model, [e in 1:E, f in 1:F], pos[e, f, 1] == (s0_f[e, f] - b⁻[e, f, 1]) + neg[e, f, 1])
    @constraint(model, [e in 1:E, f in 1:F, j in 2:J], new_sf[e, f, j] == (sf[e, f, j-1] - b⁻[e, f, j])/2 + (pos[e, f, j] + neg[e, f, j])/2)
    @constraint(model, [e in 1:E, f in 1:F], new_sf[e, f, 1] == (s0_f[e, f] - b⁻[e, f, 1])/2 + (pos[e, f, 1] + neg[e, f, 1])/2)

    # Calcul des stocks
    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], sf[e, f, j] == new_sf[e, f, j] + z⁺[e, f, j])

    @constraint(model, [e in 1:E, u in 1:U, j in 2:J], su[e, u, j] == su[e, u, j-1] + b⁺[e, u, j] - z⁻[e, u, j])
    @constraint(model, [e in 1:E, u in 1:U], su[e, u, 1] == s0_u[e, u] + b⁺[e, u, 1] - z⁻[e, u, 1])

    # Calcul des max des stocks
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J], cost_su[e, u, j] >= su[e, u, j] - r_u[e, u, j])
    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], cost_sf[e, f, j] >= sf[e, f, j] - r_f[e, f, j])

    # Création des x_u
    @constraint(model, [j in 1:J, k in 1:K, u in 1:U], x_u[j, k, u] >= sum(x[j, k, u, :]))
    @constraint(model, [j in 1:J, k in 1:K], sum(x_u[j, k, :]) <= 1)

    # Linéarisation de z⁻k = x_u * q
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J, k in 1:K], z⁻k[e, u, j, k] >= 0)
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J, k in 1:K], z⁻k[e, u, j, k] >= sum(q[j, k, :, :, e]) + x_u[j, k, u]*M - M)
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J, k in 1:K], z⁻k[e, u, j, k] <= sum(q[j, k, :, :, e]))
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J, k in 1:K], z⁻k[e, u, j, k] <= x_u[j, k, u]*M)

    # Calcul des z
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J], z⁻[e, u, j] == sum(z⁻k[e, u, j, :]))
    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], z⁺[e, f, j] == sum(q[j, :, :, f+U, e]))  

    # Contraintes d'emballages
    @constraint(model, [j in 1:J, k in 1:K], sum(q[j, k, u, f, e]*l_e[e] for e = 1:E, u in 1:(U+F), f in 1:(U+F)) <= L)

    # Calcul des x
    @constraint(model, [j in 1:J, k in 1:K, u in 1:(U+F), f in 1:(U+F)], x[j, k, u, f] >= sum(q[j, k, u, f, :]) / M )

    # Création des routes sans cycles possibles
    @constraint(model, [j in 1:J, k in 1:K, f in U+1:(U+F)], sum(x[j, k, :, f]) >= sum(x[j, k, f, :]))
    @constraint(model, [j in 1:J, k in 1:K], sum(x[j, k, :, :]) <= 4)
    @constraint(model, [j in 1:J, k in 1:K], sum(x[j, k, 1:U+F, 1:U]) == 0)
    @constraint(model, [j in 1:J, k in 1:K, u in 1:U+F, f in 1:U+F], x[j, k, u, f] <= sum(x[j, k, 1:U, :]))
    
    @constraint(model, [j in 1:J, k in 1:K, u in 1:U+F, f in 1:U+F], x[j, k, u, f] <= 1 - x[j, k, f, u])
    @constraint(model, [j in 1:J, k in 1:K, u in 1:U+F, f in 1:U+F, g in 1:U+F], x[j, k, u, f] + x[j, k, f, g] - 1 <= 1 - x[j, k, g, u])


    @objective(model, Min, sum(cost_su[e, u, j]*cs_u[e, u] for e in 1:E, u in 1:U, j in 1:J) + sum(cost_sf[e, f, j]*cs_f[e, f] for e in 1:E, f in 1:F, j in 1:J) + sum(neg[e, f, j]*cexc[e, f] for e in 1:E, f in 1:F, j in 1:J) + 
    sum(x[j, k, u, f]*γ*d[u, f] for j in 1:J, k in 1:K, u in 1:(U+F), f in 1:(U+F)) + CCam*sum(x[j, k, u, f] for j in 1:J, k in 1:K, u in 1:U, f in 1:(U+F)) + CStop * sum(x))

    optimize!(model)
    @show(objective_value(model))

    # Création et renvoit des routes

    routes = Route[]
    R = 1
    for j in 1:J
        for k in 1:K
            stops = RouteStop[]
            Fact = 0
            usi = 0
            facto1 = 0
            facto2 = 0
            for u in 1:U
                for f in 1:(U+F)
                    if (value(x[j, k, u, f]) == 1)
                        usi = u
                        facto1 = f
                        Fact += 1
                        facto2 = find(x, facto1, j, k, U, F)
                        Q = creation_Q(q, E0, E, ind_E, j, k, usi, facto1)
                        push!(stops, RouteStop(f = ind_F[facto1-U], Q = Q))
                        break
                    end
                end
            end
            if (Fact == 1)
                if (facto2 >= 0)
                    Fact += 1
                    facto3 = find(x, facto2, j, k, U, F)
                    Q = creation_Q(q, E0, E, ind_E, j, k, facto1, facto2)
                    push!(stops, RouteStop(f = ind_F[facto2-U], Q = Q))
                    if (facto3 >= 0)
                        Fact += 1
                        facto4 = find(x, facto3, j, k, U, F)
                        Q = creation_Q(q, E0, E, ind_E, j, k, facto2, facto3)
                        push!(stops, RouteStop(f = ind_F[facto3-U], Q = Q))
                        if (facto4 >= 0)
                            Fact += 1
                            Q = creation_Q(q, E0, E, ind_E, j, k, facto3, facto4)
                            push!(stops, RouteStop(f = ind_F[facto4-U], Q = Q))
                        end
                    end
                end
            end
            if (Fact > 0)
                push!(routes, Route(r=R, j = ind_J[j], x = 1, u = ind_U[usi], F = Fact, stops = stops))
                R += 1
            end
        end
    end
    su_final = collect(value(su[e, u, j]) for e in 1:E, u in 1:U, j in 1:J)
    sf_final = collect(value(sf[e, f, j]) for e in 1:E, f in 1:F, j in 1:J)
    return R-1, routes, su_final, sf_final
end

function creation_Q(q, E0, E, ind_E, j, k, u, f1)
    Q = zeros(E0)
    for e in 1:E
        Q[ind_E[e]] = value(q[j, k, u, f1, e])
    end
    return Q
end

function find(x, f, j, k, U, F)
    for g in 1:(U+F)
        if (value(x[j, k, f, g]) == 1)
            return g
        end
    end
    return -1
end












# function compute_costs()
# end

# N = 4
# b = 10
# b⁻ = [2 for i in 1:N]

# model = Model(GLPK.Optimizer)
# @variable(model, x[1:N, 1:N+1, 1:3] >= 0, Int)
# @variable(model, x0[1:N] >= 0, Int)
# @variable(model, S[1:N] >= 0, Int)
# @variable(model, c[1:N, 1:N, 3] >= 0, Int)
# @variable(model, c0[1:N] >= 0, Int)


# @constraint(model, sum(x0) <= b)
# @constraint(model, [i in 1:N], S[i] == b⁻[i])
# @constraint(model, [i in 1:N], S[i] == (x[i, N+1, 1]+x[i, N+1, 2]+x[i, N+1, 3]+ sum(x[:, i, 3])))
# @constraint(model, [i in 2:3, j in 1:N], sum(x[j, :, i]) == sum(x[:, j, i-1]))
# @constraint(model, [j in 1:N], sum(x[j, :, 1]) == x0[j])
# @constraint(model, [i in 1:N], c0[i])

# @objective(model, Min, sum(c)+ sum(c0))
# optimize!(model)
# println(termination_status(model))
# println(objective_value(model))
# for i in 1:N
#     println(value(x[i,2,2]))
# end