
function remplissage_camion_bete(Q, d, ind_U, ind_F, ind_J, ind_E, E0, emballages,L)
    # Une heuristique basique pour remplir les camions
    U, F, J, E = length(ind_U), length(ind_F), length(ind_J), length(ind_E)
    routes = []
    R = 0
    emballages_par_taille = map(x->Emballage(e=x[2],l=x[1]),sort(map(x->(x.l,x.e),emballages),rev=true))
    for j in 1:J
        for u in 1:U
            for f in 1:F
                tot_a_livrer = Q[j,u,f,:]
                i = 0
                while any(tot_a_livrer.>0)
                    contenu_camion::Vector{Int} = zeros(length(ind_E))
                    place_restante = L
                    for elem in emballages_par_taille
                        while tot_a_livrer[elem.e]>0 && place_restante>=elem.l
                            contenu_camion[elem.e]+=1
                            tot_a_livrer[elem.e]-=1
                            place_restante -= elem.l
                        end
                    end
                    i += 1
                    R+=1
                    stop = RouteStop(f=ind_F[f],Q=contenu_camion)
                    route = Route(r=R,j=j,x=1,u=ind_U[u],F=1,stops=[stop])
                    push!(routes, route)
                end
            end
        end
    end
    return routes
end

function reste_place(place_restante, emballages_par_taille, L)
    if place_restante == L
        return false
    end
    for elem in emballages_par_taille
        if (elem.l < place_restante)
            return true
        end
    end
    return false
end

function creation_dispo(usines, U, ind_E, ind_J, Q)
    dispos = zeros(length(ind_J), U, length(ind_E))
    b⁺ = collect(usines[u].b⁺[e, j] for e in ind_E, u in 1:U, j in ind_J)
    s0_u = collect(usines[u].s0[e] for e in ind_E, u in 1:U)
    for j in ind_J
        for u in 1:U
            for e in ind_E
                if j == 1
                    dispos[j, u, e] = s0_u[e, u] + b⁺[e, u, j] - sum(Q[j, u, :, e])
                else 
                    dispos[j, u, e] = dispos[j-1, u, e] + b⁺[e, u, j] - sum(Q[j, u, :, e])
                end
            end
        end
    end
    return dispos
end

function update(dispos, u, e, j, quantite)
    for jour in j:size(dispos)[1]
        dispos[jour, u, e] -= quantite
    end
    return dispos
end

function dispos_apres(dispos, j, u, e, J)
    for jour in j:J
        if (dispos[jour, u, e] <= 0)
            return false
        end
    end
    return true
end

function jours_deplaces(new_Q, j, J, dispos, u, f, emballages_par_taille, ind_E, place_restante)
    chargement_suppl = zeros(length(ind_E))
    for jour in j+1:J
        for elem in emballages_par_taille
            if (new_Q[jour, u, f, elem.e] > 0)
                nbre_partant = 0
                while (place_restante >= elem.l && dispos_apres(dispos, j, u, elem.e, J) && new_Q[jour, u, f, elem.e] > 0)
                    place_restante -= elem.l
                    nbre_partant += 1
                    dispos = update(dispos, u, elem.e, j, 1)
                    new_Q[jour, u, f, elem.e] -= 1
                    dispos = update(dispos, u, elem.e, jour, -1)
                end
                chargement_suppl[elem.e] += nbre_partant
            end
        end
    end
    return chargement_suppl, new_Q, dispos
end

function creation_contenu_camion(ind_E, L, emballages_par_taille, tot_a_livrer, j, J, new_Q, dispos, u, f)
    contenu_camion::Vector{Int} = zeros(length(ind_E))
    place_restante = L
    for elem in emballages_par_taille
        while tot_a_livrer[elem.e] > 0 && place_restante >= elem.l
            contenu_camion[elem.e] += 1
            tot_a_livrer[elem.e] -= 1
            place_restante -= elem.l
        end
    end
    if reste_place(place_restante, emballages_par_taille, L)
        chargement_suppl, new_Q, dispos = jours_deplaces(new_Q, j, J, dispos, u, f, emballages_par_taille, ind_E, place_restante)
        for elem in emballages_par_taille
            contenu_camion[elem.e] += chargement_suppl[elem.e]
        end
    end
    return contenu_camion, new_Q, dispos
end

function remplissage_camion_ultime(Q, d, ind_U, ind_F, ind_J, ind_E, E0, emballages, L, dispos)
    # Une heuristique basique pour remplir les camions
    U, F, J, E = length(ind_U), length(ind_F), length(ind_J), length(ind_E)
    routes = []
    R = 0
    new_Q = copy(Q)
    emballages_par_taille = map(x->Emballage(e=x[2],l=x[1]),sort(map(x->(x.l,x.e),emballages),rev=true))
    for j in 1:J
        for u in 1:U
            for f in 1:F
                tot_a_livrer = new_Q[j,u,f,:]
                i = 0
                while any(tot_a_livrer.>0)
                    contenu_camion, new_Q, dispos = creation_contenu_camion(ind_E, L, emballages_par_taille, tot_a_livrer, j, J, new_Q, dispos, u, f)
                    i += 1
                    R+=1
                    stop = RouteStop(f=ind_F[f],Q=contenu_camion)
                    route = Route(r=R,j=j,x=1,u=ind_U[u],F=1,stops=[stop])
                    push!(routes, route)
                end
            end
        end
    end
    return routes
end

function remplissage_camion(Q, d, ind_U, ind_F, ind_J, ind_E, E0, emballages,L)
    # Une heuristique basique pour remplir les camions
    U, F, J, E = length(ind_U), length(ind_F), length(ind_J), length(ind_E)
    routes = []
    R = 0

    for j in 1:J
        for u in 1:U
            list_F, list_livr = found_fournisseurs(Q, d, u, j)
            for idx in 1:length(list_F)
                routesjgrp = creation_routes(list_F[idx], list_livr[idx], u, j, ind_U, ind_F, ind_J, ind_E, E0, R, emballages, L)
                R+=length(routesjgrp)
                push!(routes, routesjgrp...)
            end
        end
    end

    return routes
end

function closest_fourns(noeud, d, U, F)
    l = sort(map(x->(x[2],x[1]),enumerate(d[noeud,(U+1):(U+F)])))
    return map(x->x[2],l)
end

function found_fournisseurs(Q, d, u, j)
    J = size(Q,1)
    U = size(Q,2)
    F = size(Q,3)
    E = size(Q,4)
    T_route = 4

    Qj = Q[j,:,:,:]  # A mettre a jour avec les stocks ?
    
    visited_f = falses(F)
    list_F = []
    list_livr = []

    for idxf in 1:F
        noeud_actu = u
        chemin = []
        livraisons = []
        for n in 1:T_route
            fourns_by_dist = closest_fourns(noeud_actu, d , U, F)
            
            for f in fourns_by_dist
                if !visited_f[f]
                    if d[u,f]<d[noeud_actu,f]
                        continue
                    end
                    if any(Qj[1,f,:].>=1) # Livraison urgente
                        push!(chemin, f)
                        push!(livraisons, Qj[1,f,:])
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
            push!(list_livr,livraisons)
        end
    end
    return list_F, list_livr
end


function binpack(livr, F, ind_F, ind_E, emballages::Vector{Emballage},L)::Vector{Vector{RouteStop}}
    tot_a_livrer = sum(livr)

    lst_contenus_camions = []

    emballages_par_taille = map(x->Emballage(e=x[2],l=x[1]),sort(map(x->(x.l,x.e),emballages),rev=true))
    while any(tot_a_livrer.>0)
        contenu_camion = zeros(length(ind_E))
        place_restante = L
        for elem in emballages_par_taille
            while tot_a_livrer[elem.e]>0 && place_restante>=elem.l
                contenu_camion[elem.e]+=1
                tot_a_livrer[elem.e]-=1
                place_restante -= elem.l
            end
        end
        push!(lst_contenus_camions,contenu_camion)
    end

    ## Determination des stops

    lst_camions = []

    for cont_cam in lst_contenus_camions
        camion = []
        for (idf,f) in enumerate(F)
            vec_a_poser = zeros(length(emballages))
            for elt in emballages
                if livr[idf][elt.e]>0 && cont_cam[elt.e]>0
                    e_a_poser = min(livr[idf][elt.e],cont_cam[elt.e])
                    cont_cam[elt.e] -= e_a_poser
                    livr[idf][elt.e] -= e_a_poser
                    vec_a_poser[elt.e] = e_a_poser
                end
            end
            if any(vec_a_poser.>0)
                push!(camion,RouteStop(f=ind_F[f],Q = vec_a_poser))
            end
        end
        if length(camion)>0
            push!(lst_camions,camion)
        end
    end

    return lst_camions

end

function creation_routes(F, livraison, u, j, ind_U, ind_F, ind_J, ind_E, E0, R, emballages,L)
    
    nb_stops = length(F)
    cur_R = R

    routes = []
    cam_stops_list = binpack(livraison, F, ind_F, ind_E, emballages,L) #Array de arrays de routestops

    for cam_stops in cam_stops_list
        cur_R += 1
        push!(routes, Route(r=cur_R, j=ind_J[j], x=1, u=ind_U[u], F=length(cam_stops), stops=cam_stops))
    end

    return routes
end