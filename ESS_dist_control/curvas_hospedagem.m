    for k=1:34
    if k==1
        nc_pv(k)=pc_pv(k)*100/45;
    else
        nc_pv(k)=nc_pv(k-1)+pc_pv(k)*100/45;
    end
end

for k=1:34
    if k==1
        nd_pv(k)=pd_pv(k)*100/45;
    else
        nd_pv(k)=nd_pv(k-1)+pd_pv(k)*100/45;
    end
end
    

    figure (2)
    bar([1:34],nc_pv,'LineWidth',1.5)
    %Configuração do Grafico
    xlabel('Prossumidores ');
    ylabel('Nível de penetração PV (%)');
    grid on
    %Configuração da Figura
    set(gca,'FontWeight','bold','FontSize',25,'FontName','LM Roman 10');
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];
    
    figure (3)
    bar([1:34],nd_pv,'LineWidth',1.5)
    %Configuração do Grafico
    xlabel('Prossumidores ');
    ylabel('Nível de penetração PV (%)');
    grid on
    %Configuração da Figura
    set(gca,'FontWeight','bold','FontSize',25,'FontName','LM Roman 10');
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];