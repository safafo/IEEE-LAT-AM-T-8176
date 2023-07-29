function X = dispacth_ADD(bess_name,lb_name)
    %bess_name = nome do bess
    %lb_name = curva de despacho
    X=strcat('New LoadShape.dispatchshape',num2str(bess_name),' interval=0.25 npts=96 mult=[',num2str(lb_name),']');
end