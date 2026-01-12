SELECT 
    ft.trade_id,
    ft.order_id,
    t.trader_name,
    p.portfolio_name,
    c.company_name,
    s.sector_name,
    e.exchange_name,
    ft.date,
    cal.year,
    cal.month,
    cal.day,
    ft.quantity,
    ft.price,
    (ft.quantity * ft.price) AS trade_value
FROM fact_trades ft
JOIN fact_orders o 
    ON ft.order_id = o.order_id
JOIN dim_trader t 
    ON ft.trader_id = t.trader_id
JOIN dim_portfolio p 
    ON ft.portfolio_id = p.portfolio_id
JOIN dim_company c 
    ON ft.company_id = c.company_id
JOIN dim_sector s 
    ON c.sector_id = s.sector_id
JOIN dim_exchange e 
    ON c.exchange_id = e.exchange_id
JOIN dim_calendar cal 
    ON ft.date = cal.date;

-- TOTAL MARKET CAPITALIZATION
SELECT 
    CONCAT(ROUND(SUM(share_price * outstanding_shares) / 1000000, 2), ' M') AS total_market_capitalization
FROM stock;

-- AVERAGE DAILY TRADING VOLUME
SELECT 
    ROUND(AVG(volume), 0) AS overall_avg_daily_volume
FROM fact_daily_prices;

-- VOLATILITY
SELECT 
    ROUND(STDDEV((close - open) / open) * 100, 2) AS market_volatility_pct
FROM fact_daily_prices;

-- TOP PERFORMING SECTOR
SELECT 
    sector, 
    ROUND(AVG(return_pct), 2) AS avg_sector_return
FROM stock
GROUP BY sector
ORDER BY avg_sector_return DESC
LIMIT 1;

-- PORTFOLIO VALUE
SELECT 
    ROUND(SUM(quantity * current_price), 0) AS total_portfolio_value
FROM stock;

-- PORTFOLIO RETURN %
SELECT 
    ROUND((SUM(current_value) - SUM(initial_value)) / SUM(initial_value) * 100, 2) AS portfolio_return_pct
FROM stock;

-- SHARPE RATIO
SELECT 
    ROUND(
        ( ((SUM(current_value) - SUM(initial_value)) / SUM(initial_value)) - 0.05 ) 
        / 0.07, 
    2) AS sharpe_ratio
FROM stock;

-- ORDER EXECUTION RATE
SELECT 
   ROUND(( (SELECT COUNT(*) FROM fact_trades) * 100.0 / (SELECT COUNT(*) FROM fact_orders) ), 0) AS execution_rate;
   
-- TRADE WIN RATE
SELECT 
    ROUND(SUM(win_flag) * 100.0 / COUNT(*), 0) AS trade_win_rate
FROM fact_trades_pnl_kpi;

-- TRADER PERFORMANCE (P&L)
SELECT 
    CONCAT(ROUND(SUM(realized_profit) / 1000000, 0) ,'M') AS total_pnl_millions
FROM fact_trades_pnl_kpi;

-- TOP 5 SECTORS BY PROFIT
SELECT 
    s.sector_name, 
    CONCAT(ROUND(SUM(pnl.realized_profit) / 1000000, 2), ' M') AS total_profit
FROM fact_trades_pnl_kpi pnl
JOIN dim_company c ON pnl.company_id = c.company_id
JOIN dim_sector s ON c.sector_id = s.sector_id
GROUP BY s.sector_name
ORDER BY SUM(pnl.realized_profit) DESC
LIMIT 5;

-- TOP 5 TRADERS BY PROFIT
SELECT 
    t.trader_name,
    CONCAT(ROUND(SUM(pnl.realized_profit) / 1000000, 2), ' M') AS total_profit
FROM fact_trades_pnl_kpi pnl
JOIN dim_trader t ON pnl.trader_id = t.trader_id
GROUP BY t.trader_name
ORDER BY SUM(pnl.realized_profit) DESC
LIMIT 5;

-- MONTHLY REALIZED PROFIT
SELECT 
    cal.`Month Name`, 
    CONCAT(ROUND(SUM(pnl.realized_profit) / 1000000, 2), ' M') AS monthly_profit 
FROM fact_trades_pnl_kpi pnl 
JOIN dim_calendar cal ON pnl.calendar_id = cal.calendar_id 
GROUP BY cal.`Month Name`, cal.month 
ORDER BY cal.month ASC;

-- COUNTRY WISE PROFIT
SELECT 
    e.country, 
    CONCAT(ROUND(SUM(pnl.realized_profit) / 1000000, 2), ' M') AS total_profit 
FROM fact_trades_pnl_kpi pnl 
JOIN dim_company c ON pnl.company_id = c.company_id 
JOIN dim_exchange e ON c.exchange_id = e.exchange_id 
GROUP BY e.country 
ORDER BY SUM(pnl.realized_profit) DESC;
