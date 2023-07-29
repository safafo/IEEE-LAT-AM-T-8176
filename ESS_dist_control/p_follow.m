figure (1)
for i=1:34
    plot (lb(i,:));
    hold on 
end
hold off
figure (2)
for i=1:34
    plot (lb(i,:)*p_ess(i));
    hold on 
end
hold off