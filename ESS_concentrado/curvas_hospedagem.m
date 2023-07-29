    for k=1:34
    if k==1
        nc_pv(k)=pc_pv(k);
    else
        nc_pv(k)=nc_pv(k-1)+pc_pv(k);
    end
end

for k=1:34
    if k==1
        nd_pv(k)=pd_pv(k);
    else
        nd_pv(k)=nd_pv(k-1)+pd_pv(k);
    end
end
    

    figure (2)
    bar([1:34],nc_pv,'LineWidth',1.5)
    %Configuração do Grafico
    xlabel('Prossumidores ');
    ylabel('Nível de penetração PV (%)');
    grid on
    %Configuração da Figura
    set(gca,'FontSize',25);
    fig=gcf;
    fig.PaperUnits='inches';
    fig.PaperPosition=[0 0 16 8];
    fig.PaperSize=[16 8];
    
    
    figure (3)
    bar([1:34],nd_pv,'LineWidth',1.5)
    %Configuração do Grafico
    xlabel('Prossumidores ');
    ylabel('Nível de penetração PV (%)');
    grid on
    %Configuração da Figura
    set(gca,'FontSize',25);
    fig=gcf;
    fig.PaperUnits='inches';
    fig.PaperPosition=[0 0 16 8];
    fig.PaperSize=[16 8];