
figure('Name',strcat('Simulação ',num2str(simul)))
% lim_trafo=(-45*0.85)+zeros(1,96);
for z= Simuls 
    if z~=0
        plot(eval(strcat('-1*sum(Pot_Trafo_',num2str(z),'(:,1:3),2)')),'DisplayName',strcat('P',num2str(round(nd_pv(z))),'%'));
        hold on 
    else
        plot(eval(strcat('-1*sum(Pot_Trafo_',num2str(z),'(:,1:3),2)')),'DisplayName','P 0%');
        hold on;
    end
end
% plot(lim_trafo,'color','r','DisplayName','Limite');
hold off;
    title(strcat('Potência Real no transformador para diferentes níveis de penetração PV')) 
    grid on,
    xlabel('Tempo (Horas)');
    ylabel('Potência (kW)');
    legend show
    set(gca,'FontWeight','bold','LineWidth',1,'FontSize',25,'FontName','LM Roman 10','XTick',xtickv,'XTickLabel',2:2:24);
    fig=gcf;
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0 0 10 4];
    fig.PaperSize = [10 4];
    
    