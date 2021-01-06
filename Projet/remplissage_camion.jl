function remplissage_camion(Q, d, ind_U, ind_F, ind_J, ind_E, E0)
    # Une heuristique basique pour remplir les camions
    # A AMELIIORER
    
    U, F, J, E = length(ind_U), length(ind_F), length(ind_J), length(ind_E)

    routes = []
    R = 0

    for j in 1:J
        for u in 1:U
            list_F = found_fournisseurs(Q, d, u, j)
            for F in list_F
                R += 1
                push!(routes, creation_routes(F, Q, u, j, ind_U, ind_F, ind_J, ind_E, E0, R))    
            end
        end
    end

    return routes
end

function closest_fourns(noeud, d, U, F)
    l = sort(map(x->(x[2],x[1]),enumerate(d[noeud.v,(U+1):(U+F)])))
    return map(x->x[2],l)
end

function found_fournisseurs(Q, d, u, j)
    J = size(Q,1)
    U = size(Q,2)
    F = size(Q,3)
    E = size(Q,4)
    T_route = 4

    duree_anticipation = min(4,J-j)

    stocksj = [] #A ajouter

    Qj = Q[j,:,:,:]  # A mettre a jour avec les stocks
    Qanticip = sum(Q[j:duree_anticipation,:,:,:],dims=1)[1,:,:,:] # U*F*E
    
    visited_f = falses(F)
    list_F = []

    for idx in 1:F
        noeud_actu = u
        chemin = []
        for n in 1:T_route
            fourns_by_dist = closest_fourns(noeud, d , U, F)
            
            for f in fourns_by_dist_of_u
                if !visited_f[f]
                    if d[u,f]<d[noeud_actu,f]
                        continue
                    end
                    if any(Qj[1,f,:].>=1) # Livraison urgente
                        #ajouter le fournisseur f a chemin
                        visited_f[f] = true
                        noeud_actu = f
                        break
                    end
                    if sum(Qanticip[1,f,:])>=10 && d[noeud_actu,f]<d[u,noeud_actu] # Livraison anticipée 
                        #ajouter le fournisseur f a chemin
                        visited_f[f] = true
                        noeud_actu = f
                        break
                    end
                    visited_f[f] = true
                end
            end
        end
        if length(chemin)>0
            push!(list_F,chemin)
        end
    end
    return list_F
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