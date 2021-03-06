--AJOUT DE CONTROLLER KNOT

s = $ -- selection de la spline
hlp_spline_pos = s.parent -- selection du controller spline
k_select = getKnotSelection s 1 -- recolte du numero de vertex du knot ajout�
--setknotselection 

animatevertex s (k_select[1]*3 ) -- cr�ation de controller sur un vecteur du point ajout�
animatevertex s (k_select[1]*3 - 1) -- cr�ation de controller sur le point ajout�
animatevertex s (k_select[1]*3 - 2) -- cr�ation de controller sur un vecteur du point ajout�

--cr�ations des helpers 
hlp_ctr_mid = 			point name: (uniquename "hlp_ctr_mid") radius:10 pos: (getKnotPoint s 1 k_select[1])
hlp_ctr_mid_in = 		point name: (uniquename "hlp_ctr_mid") radius:10 pos: (getinvec s 1 k_select[1])
hlp_ctr_mid_out = 	point name: (uniquename "hlp_ctr_mid") radius:10 pos: (getoutvec s 1 k_select[1])

-- parent� des helpers
hlp_ctr_mid_in.parent = hlp_ctr_mid
hlp_ctr_mid_out.parent = hlp_ctr_mid

ctr_knot = #(hlp_ctr_mid_in, hlp_ctr_mid, hlp_ctr_mid_out)


-- contraintes des knots aux helpers
-- contrainte en position du knot
for i = 1 to 3 do
(
s[4][8][(k_select[1]*3 - 3 + i)].controller = point3_script ()
s[4][8][(k_select[1]*3 - 3 + i)].addconstant "hlp_ctr_mid" ctr_knot[i]
s[4][8][(k_select[1]*3 - 3 + i)].addconstant "hlp_spline_pos" hlp_spline_pos
s[4][8][(k_select[1]*3 - 3 + i)].script = "in coordsys hlp_spline_pos hlp_ctr_mid.pos"
)

-- contrainte en position du vector in
-- contrainte en position du vector out

-- creation des splines controlleurs
-- contraintes en positions des helpers

