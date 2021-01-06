function remplissage_camion(Q, ind_U, ind_F, ind_J, ind_E, E0)
    # Une heuristique basique pour remplir les camions
    # A AMELIIORER
    
    U, F, J, E = length(ind_U), length(ind_F), length(ind_J), length(ind_E)

    routes = []
    R = 0

    for j in 1:J
        for u in 1:U
            list_F = found_fournisseurs(Q, u, j)
            for F in list_F
                R += 1
                push!(routes, creation_routes(F, Q, u, j, ind_U, ind_F, ind_J, ind_E, E0, R))    
            end
        end
    end

    return routes
end

function found_fournisseurs(Q, u, j)
    list_F = []
end

function creation_routes(F, Q, u, j, ind_U, ind_F, ind_J, ind_E, E0, R)
    stops = []
    
    for f in 1:length(F)
        Quantities = zeros(E0)
        for e in 1:length(ind_E)
            Quantities[ind_E[e]] = Q[j, u, f, e]
        end
        push!(stops, RouteStop(f=ind_F[f], Q=Quantites))
    end

    return Route(r=R, j=ind_J[j], x=1, u=ind_U[u], F=length(F), stops=stops)
end