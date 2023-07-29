function X = PV_ADD(n_phases,pv_name,bus_name,pot)
    %n_phases = número de fases 
    %pv_names = nome do pv
    %bus_name = nome da barra
    %pot = potencia nominal do PV
    if n_phases==num2str(1)
        X = strcat('New PVSystem.PV',num2str(pv_name),' phases=',num2str(n_phases),' bus1=',bus_name,' kV=0.127 kVA=',num2str(pot),' irrad=1 Pmpp=',num2str(pot),' temperature=25 PF=1 %Pmpp=100 %cutout=0 %cutin=0 effcurve=Myeff P-TCurve=MyPvsT Daily=Irrad_1 TDaily=Temp_1');
    else
        X = strcat('New PVSystem.PV',num2str(pv_name),' phases=',num2str(n_phases),' bus1=',bus_name,' kV=0.22 kVA=',num2str(pot),' irrad=1 Pmpp=',num2str(pot),' temperature=25 PF=1 %Pmpp=100 %cutout=0 %cutin=0 effcurve=Myeff P-TCurve=MyPvsT Daily=Irrad_1 TDaily=Temp_1');
    end
end