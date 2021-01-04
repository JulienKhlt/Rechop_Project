include("Solution.jl")


struct Instance1Emb
    instance::Instance
    iemb::Int

    Instance1Emb(; instance, iemb) = new(instance, iemb)
end

function new_usi(usi::Usine, iemb::Int)::Usine
    newcs = [usi.cs[iemb]]
    news0 = [usi.s0[iemb]]
    newb = Matrix{Int64}(undef,1,21)
    newb[1,:] = usi.b⁺[iemb,:]
    newr = Matrix{Int64}(undef,1,21)
    newr[1,:] = usi.r[iemb,:]

    return Usine(u=usi.u, v=usi.v, coor=usi.coor, cs=newcs, s0=news0, b⁺=newb, r=newr)
end

function new_fourn(fourn::Fournisseur, iemb::Int)::Fournisseur
    newcs = [fourn.cs[iemb]]
    newcexc = [fourn.cexc[iemb]]
    news0 = [fourn.s0[iemb]]
    newb = Matrix{Int64}(undef,1,21)
    newb[1,:] = fourn.b⁻[iemb,:]
    newr = Matrix{Int64}(undef,1,21)
    newr[1,:] = fourn.r[iemb,:]

    return Fournisseur(f=fourn.f, v=fourn.v, coor=fourn.coor, cs=newcs, cexc=newcexc, s0=news0, b⁻=newb, r=newr)
end

function instance_1_emballage(instance::Instance,iemb::Int)::Instance1Emb
    newE = 1
    newEmballages = [Emballage(e=1,l=instance.emballages[iemb].l)]

    newUsines = Vector{Usine}()
    newU = 0
    for usi in instance.usines
        if usi.s0[iemb]>0
            newU+=1
            push!(newUsines,new_usi(usi,iemb))
            continue
        end
        for j in 1:instance.J
            if usi.b⁺[iemb,j]>0
                push!(newUsines,new_usi(usi,iemb))
                newU+=1
                break
            end
        end
    end

    newFournisseurs = Vector{Fournisseur}()
    newF = 0
    for fourn in instance.fournisseurs
        for j in 1:instance.J
            if fourn.b⁻[iemb,j]>0
                push!(newFournisseurs,new_fourn(fourn,iemb))
                newF+=1
                break
            end
        end
    end

    # G = SimpleDiGraph(newU + newF)
    # d = spzeros(newU + newF, newU + newF)
    # for s1 in vcat(newUsines,newFournisseurs)
    #     v1 = s1.v
    #     for s2 in vcat(newUsines,newFournisseurs)
    #         v2 = s2.v
    #         if instance.graphe.d[v1,v2] > eps()
    #             add_edge!(G, a.v1, a.v2)
    #             d[v1, v2] = instance.graphe.d[v1,v2]
    #         end
    #     end
    # end
    # newGraphe = Graphe(G = G, d = d)

    return Instance1Emb(iemb=iemb, instance=Instance(J=instance.J, U=newU, F=newF, E=newE, L=instance.L, γ=instance.γ, ccam=instance.ccam, cstop=instance.cstop, emballages=newEmballages, usines=newUsines, fournisseurs=newFournisseurs, graphe=instance.graphe))
end

function instances_par_emballage(instance::Instance)::Vector{Instance1Emb}
    instances = Vector{Instance1Emb}()
    for iemb in 1:instance.E
        push!(instances,instance_1_emballage(instance,iemb))
    end
    return instances
end
