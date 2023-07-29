function X = BESS_ADD(n_phases,bess_name,bus_name,pot,cap)
% pot = 2;
% cap = 10;
%n_phases = número de fases 
    %bess_names = nome do bess e da cruva de despacho
    %bus_name = nome da barra
    %pot = potencia nominal do BESS
    %cap= capacidade de armazenamento
    if n_phases==num2str(1)
        X=strcat('New Storage.BESS',num2str(bess_name),' phases=',num2str(n_phases),' bus1=',bus_name,' kV=0.127 pf=1 kWrated=',num2str(pot),' %reserve=12.1 effcurve=Myeff kWhrated= ',num2str(cap),'%IdlingkW=1 %stored=12.1 state=idling debugtrace=yes dispmode=follow model=1 daily=dispatchshape',num2str(bess_name));
    else
        X=strcat('New Storage.BESS',num2str(bess_name),' phases=',num2str(n_phases),' bus1=',bus_name,' kV=0.22 pf=1 kWrated=',num2str(pot),' %reserve=12.1 effcurve=Myeff kWhrated= ',num2str(cap),'%IdlingkW=1 %stored=12.1 state=idling debugtrace=yes dispmode=follow model=1 daily=dispatchshape',num2str(bess_name));

    end
end

 