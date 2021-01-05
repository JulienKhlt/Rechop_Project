include("code_Julia/route.jl")
using JuMP, Gurobi

function data(usines, fournisseurs, emballages, E, U, F, J, L)
    b⁺ = collect(usines[u].b⁺[e, j] for e = 1:E, u = 1:U, j = 1:J)
    b⁻ = collect(fournisseurs[f].b⁻[e, j] for e = 1:E, f = 1:F, j = 1:J)
    r_u = collect(usines[u].r[e, j] for e = 1:E, u = 1:U, j = 1:J)
    r_f = collect(fournisseurs[f].r[e, j] for e = 1:E, f = 1:F, j = 1:J)
    cs_u = collect(usines[u].cs[e] for e = 1:E, u = 1:U)
    cs_f = collect(fournisseurs[f].cs[e] for e = 1:E, f = 1:F)
    cexc = collect(fournisseurs[f].cexc[e] for e = 1:E, f = 1:F)
    s0_u = collect(usines[u].s0[e] for e = 1:E, u = 1:U)
    s0_f = collect(fournisseurs[f].s0[e] for e = 1:E, f = 1:F)
    l_e = collect(emballages[e].l for e = 1:E)
    number_of_e = []
    for e in 1:E
        push!(number_of_e, ceil(L/l_e[e]))
    end
    return b⁺, b⁻, r_u, r_f, cs_u, cs_f, cexc, l_e, s0_u, s0_f, number_of_e
end




function PNLE_entier(usines, fournisseurs, emballages, J, U, F, E, K, L, γ, CStop, CCam, d, notrelaxed = true)
    b⁺, b⁻, r_u, r_f, cs_u, cs_f, cexc, l_e, s0_u, s0_f, number_of_e = data(usines, fournisseurs, emballages, E, U, F, J, L)

    M = maximum(number_of_e)
    model = Model(optimizer_with_attributes(Gurobi.Optimizer,"TimeLimit"=>300,"OutputFlag"=>1))
    @variable(model, q[1:J, 1:K, 1:U+F, 1:U+F, 1:E] >= 0, integer = notrelaxed)
    @variable(model, x[1:J, 1:K, 1:U+F, 1:U+F], Bin)
    @variable(model, x_u[1:J, 1:K, 1:U], Bin)



    @variable(model, sf[1:E, 1:F, 1:J] >= 0, integer = notrelaxed)
    @variable(model, su[1:E, 1:U, 1:J] >= 0, integer = notrelaxed)

    @variable(model, z⁻[1:E, 1:U, 1:J] >= 0)
    @variable(model, z⁻k[1:E, 1:U, 1:J, 1:K] >= 0)

    @variable(model, z⁺[1:E, 1:F, 1:J] >= 0)

    @variable(model, new_sf[1:E, 1:F, 1:J] >= 0)
    @variable(model, pos[1:E, 1:F, 1:J] >= 0)
    @variable(model, neg[1:E, 1:F, 1:J] >= 0)

    @variable(model, cost_su[1:E, 1:U, 1:J] >= 0)
    @variable(model, cost_sf[1:E, 1:F, 1:J] >= 0)

    @constraint(model, [e in 1:E, f in 1:F, j in 2:J], pos[e, f, j] == (sf[e, f, j-1] - b⁻[e, f, j]) + neg[e, f, j])
    @constraint(model, [e in 1:E, f in 1:F], pos[e, f, 1] == (s0_f[e, f] - b⁻[e, f, 1]) + neg[e, f, 1])
    @constraint(model, [e in 1:E, f in 1:F, j in 2:J], new_sf[e, f, j] == (sf[e, f, j-1] - b⁻[e, f, j])/2 + (pos[e, f, j] + neg[e, f, j])/2)
    @constraint(model, [e in 1:E, f in 1:F], new_sf[e, f, 1] == (s0_f[e, f] - b⁻[e, f, 1])/2 + (pos[e, f, 1] + neg[e, f, 1])/2)

    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], sf[e, f, j] == new_sf[e, f, j] + z⁺[e, f, j])

    @constraint(model, [e in 1:E, u in 1:U, j in 2:J], su[e, u, j] == su[e, u, j-1] + b⁺[e, u, j] - z⁻[e, u, j])
    @constraint(model, [e in 1:E, u in 1:U], su[e, u, 1] == s0_u[e, u] + b⁺[e, u, 1] - z⁻[e, u, 1])

    @constraint(model, [e in 1:E, u in 1:U, j in 1:J], cost_su[e, u, j] >= su[e, u, j] - r_u[e, u, j])
    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], cost_sf[e, f, j] >= sf[e, f, j] - r_f[e, f, j])

    @constraint(model, [j in 1:J, k in 1:K, u in 1:U], x_u[j, k, u] >= sum(x[j, k, u, :]))
    @constraint(model, [j in 1:J, k in 1:K], sum(x_u[j, k, :]) <= 1)
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J, k in 1:K], z⁻k[e, u, j, k] >= 0)
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J, k in 1:K], z⁻k[e, u, j, k] >= sum(q[j, k, :, :, e]) + x_u[j, k, u]*M - M)
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J, k in 1:K], z⁻k[e, u, j, k] <= sum(q[j, k, :, :, e]))
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J, k in 1:K], z⁻k[e, u, j, k] <= x_u[j, k, u]*M)
    @constraint(model, [e in 1:E, u in 1:U, j in 1:J], z⁻[e, u, j] == sum(z⁻k[e, u, j, :]))
    @constraint(model, [e in 1:E, f in 1:F, j in 1:J], z⁺[e, f, j] == sum(q[j, :, :, f+U, e]))  

    @constraint(model, [j in 1:J, k in 1:K], sum(q[j, k, u, f, e]*l_e[e] for e = 1:E, u in 1:(U+F), f in 1:(U+F)) <= L)

    @constraint(model, [j in 1:J, k in 1:K, u in 1:(U+F), f in 1:(U+F)], x[j, k, u, f] >= sum(q[j, k, u, f, :]) / M )

    # @constraint(model, [j in 1:J, k in 1:K], sum(x[j, k, 1:U, :]) <= 1)
    @constraint(model, [j in 1:J, k in 1:K, f in U+1:(U+F)], sum(x[j, k, :, f]) >= sum(x[j, k, f, :]))
    @constraint(model, [j in 1:J, k in 1:K], sum(x[j, k, :, :]) <= 4)
    @constraint(model, [j in 1:J, k in 1:K], sum(x[j, k, 1:U+F, 1:U]) == 0)
    @constraint(model, [j in 1:J, k in 1:K, u in 1:U+F, f in 1:U+F], x[j, k, u, f] <= sum(x[j, k, 1:U, :]))
    
    # @constraint(model, [j in 1:J, k in 1:K, u in 1:U+F], x[j, k, u, u] == 0)
    @constraint(model, [j in 1:J, k in 1:K, u in 1:U+F, f in 1:U+F], x[j, k, u, f] <= 1 - x[j, k, f, u])
    @constraint(model, [j in 1:J, k in 1:K, u in 1:U+F, f in 1:U+F, g in 1:U+F], x[j, k, u, f] + x[j, k, f, g] - 1 <= 1 - x[j, k, g, u])


    @objective(model, Min, sum(cost_su[e, u, j]*cs_u[e, u] for e in 1:E, u in 1:U, j in 1:J) + sum(cost_sf[e, f, j]*cs_f[e, f] for e in 1:E, f in 1:F, j in 1:J) + sum(neg[e, f, j]*cexc[e, f] for e in 1:E, f in 1:F, j in 1:J) + 
    sum(x[j, k, u, f]*γ*d[u, f] for j in 1:J, k in 1:K, u in 1:(U+F), f in 1:(U+F)) + CCam*sum(x[j, k, u, f] for j in 1:J, k in 1:K, u in 1:U, f in 1:(U+F)) + CStop * sum(x))

    optimize!(model)
    @show(objective_value(model))

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
                        Q = creation_Q(q, E, j, k, usi, facto1)
                        push!(stops, RouteStop(f = facto1-U, Q = Q))
                        println("facto1 = ", facto1)
                        println("facto2 = ", facto2)
                        break
                    end
                end
            end
            if (Fact == 1)
                if (facto2 >= 0)
                    Fact += 1
                    facto3 = find(x, facto2, j, k, U, F)
                    println("facto3 = ", facto3)
                    Q = creation_Q(q, E, j, k, facto1, facto2)
                    push!(stops, RouteStop(f = facto2-U, Q = Q))
                    if (facto3 >= 0)
                        Fact += 1
                        facto4 = find(x, facto3, j, k, U, F)
                        println("facto4 = ", facto4)
                        Q = creation_Q(q, E, j, k, facto2, facto3)
                        push!(stops, RouteStop(f = facto3-U, Q = Q))
                        if (facto4 >= 0)
                            Fact += 1
                            Q = creation_Q(q, E, j, k, facto3, facto4)
                            push!(stops, RouteStop(f = facto4-U, Q = Q))
                        end
                    end
                end
            end
            if (Fact > 0)
                push!(routes, Route(r=R, j = j, x = 1, u = usi, F = Fact, stops = stops))
                R += 1
            end
        end
    end
    return R-1, routes
end

function creation_Q(q, E, j, k, u, f1)
    Q = []
    for e in 1:E
        push!(Q, value(q[j, k, u, f1, e]))
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