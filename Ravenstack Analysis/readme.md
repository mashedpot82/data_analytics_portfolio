# Customer Churn Analysis of the Ravenstack Company
This folder contains a churn analysis of the ravenstack company using sql and tableau. 
The goal of this project is to verify three hypotheses that I have regarding the ravenstack dataset:
1. Churn is denser in some industries: Most churn happens in one or two industries
2. Churn is seasonal: Most churn happens in a particular set of months
3. Churn is subscription tier localized: Most churn happens in a particular subscription tier
<br>

# The tasks for this project are: 

### Calculate three relevant KPI's:
Montly Churn Rate
- The percentage rate at which customers stop subscribing to our service in a given period.
  
  $$\frac{Customers \enspace Lost \enspace in \enspace a \enspace month}{Total \enspace Customers \enspace in \enspace the \enspace start \enspace of \enspace a\enspace Period}*100$$

Churn Rate per Industry
- The percentage rate at which customers of a given **industry** stop subscribing to our service .
  
  $$\frac{Customers \enspace Lost \enspace at \enspace a \enspace given \enspace industry}{Total \enspace Customers \enspace in \enspace that \enspace industry}*100$$

Churn Rate per plan
- The percentage rate at which customers of a given **plan-tier** stop subscribing to our service .
  
  $$\frac{Customers \enspace Lost \enspace at \enspace a \enspace given \enspace plan-tier}{Total \enspace Customers \enspace in \enspace that \enspace plan-tier}*100$$  

<br>

### Visualize monthly churn rate using a tableau dashboard

<br>


# About the Dataset: Ravenstack
RavenStack is a fictional AI-powered collaboration platform used to simulate a real-world SaaS business. This simulated dataset was created using Python and ChatGPT specifically for people learning data analysis, business intelligence, or data science. It offers a realistic environment to practice SQL joins, cohort analysis, churn modeling, revenue tracking, and support analytics using a multi-table relational structure.

<br>


# Contents of this Folder
- **Ravenstack.sql:**  Sql script file used in transforming, cleaning and joining relevant tables in order to compute the KPI's
- **Monthly Churn Rate.twb:** Tableau Workbook file that contains a dashboard of the computed monthly churn rate. The dashboard tries to answer whether churn is seasonal or not
- ** **
