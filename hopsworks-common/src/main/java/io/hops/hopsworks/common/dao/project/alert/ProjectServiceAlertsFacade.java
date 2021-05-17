/*
 * This file is part of Hopsworks
 * Copyright (C) 2021, Logical Clocks AB. All rights reserved
 *
 * Hopsworks is free software: you can redistribute it and/or modify it under the terms of
 * the GNU Affero General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Hopsworks is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */
package io.hops.hopsworks.common.dao.project.alert;

import io.hops.hopsworks.common.dao.AbstractFacade;
import io.hops.hopsworks.persistence.entity.alertmanager.AlertSeverity;
import io.hops.hopsworks.persistence.entity.alertmanager.AlertType;
import io.hops.hopsworks.persistence.entity.project.Project;
import io.hops.hopsworks.persistence.entity.project.alert.ProjectServiceAlert;
import io.hops.hopsworks.persistence.entity.project.alert.ProjectServiceAlertStatus;
import io.hops.hopsworks.persistence.entity.project.service.ProjectServiceEnum;
import io.hops.hopsworks.persistence.entity.user.activity.Activity;

import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.NoResultException;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;
import javax.persistence.TypedQuery;
import java.util.Date;
import java.util.Set;

@Stateless
public class ProjectServiceAlertsFacade extends AbstractFacade<ProjectServiceAlert> {

  @PersistenceContext(unitName = "kthfsPU")
  private EntityManager em;

  public ProjectServiceAlertsFacade() {
    super(ProjectServiceAlert.class);
  }

  @Override
  protected EntityManager getEntityManager() {
    return em;
  }

  public ProjectServiceAlert findByProjectAndId(Project project, Integer id) {
    TypedQuery<ProjectServiceAlert> query =
        em.createNamedQuery("ProjectServiceAlert.findByProjectAndId", ProjectServiceAlert.class);
    query.setParameter("project", project).setParameter("id", id);
    try {
      return query.getSingleResult();
    } catch (NoResultException e) {
      return null;
    }
  }

  public ProjectServiceAlert findByProjectAndStatus(Project project, ProjectServiceAlertStatus status) {
    TypedQuery<ProjectServiceAlert> query =
        em.createNamedQuery("ProjectServiceAlert.findByProjectAndStatus", ProjectServiceAlert.class);
    query.setParameter("project", project).setParameter("status", status);
    try {
      return query.getSingleResult();
    } catch (NoResultException e) {
      return null;
    }
  }

  public CollectionInfo findAllProjectAlerts(Integer offset, Integer limit, Set<? extends FilterBy> filter,
      Set<? extends SortBy> sort, Project project) {
    String queryStr = buildQuery("SELECT a FROM ProjectServiceAlert a ", filter, sort, "a.project = :project ");
    String queryCountStr =
        buildQuery("SELECT COUNT(a.id) FROM ProjectServiceAlert a ", filter, sort, "a.project = :project ");
    Query query = em.createQuery(queryStr, Activity.class).setParameter("project", project);
    Query queryCount = em.createQuery(queryCountStr, Activity.class).setParameter("project", project);
    return findAll(offset, limit, filter, query, queryCount);
  }

  private CollectionInfo findAll(Integer offset, Integer limit,
      Set<? extends FilterBy> filter, Query query, Query queryCount) {
    setFilter(filter, query);
    setFilter(filter, queryCount);
    setOffsetAndLim(offset, limit, query);
    return new CollectionInfo((Long) queryCount.getSingleResult(), query.getResultList());
  }

  private void setFilter(Set<? extends FilterBy> filter, Query q) {
    if (filter == null || filter.isEmpty()) {
      return;
    }
    for (FilterBy aFilter : filter) {
      setFilterQuery(aFilter, q);
    }
  }

  private void setFilterQuery(FilterBy filterBy, Query q) {
    switch (ProjectServiceAlertsFacade.Filters.valueOf(filterBy.getValue())) {
      case TYPE:
        q.setParameter(filterBy.getField(), getEnumValues(filterBy, AlertType.class));
        break;
      case STATUS:
        q.setParameter(filterBy.getField(), getEnumValues(filterBy, ProjectServiceAlertStatus.class));
        break;
      case SEVERITY:
        q.setParameter(filterBy.getField(), getEnumValues(filterBy, AlertSeverity.class));
        break;
      case SERVICE:
        q.setParameter(filterBy.getField(), getEnumValues(filterBy, ProjectServiceEnum.class));
        break;
      case CREATED:
      case CREATED_GT:
      case CREATED_LT:
        Date date = getDate(filterBy.getField(), filterBy.getParam());
        q.setParameter(filterBy.getField(), date);
        break;
      default:
        break;
    }
  }

  public enum Sorts {
    ID("ID", "a.id ", "ASC"),
    TYPE("TYPE", "a.alertType ", "ASC"),
    STATUS("STATUS", "a.status ", "ASC"),
    SEVERITY("SEVERITY", "a.severity ", "ASC"),
    CREATED("CREATED", "a.created ", "DESC");

    private final String value;
    private final String sql;
    private final String defaultParam;

    Sorts(String value, String sql, String defaultParam) {
      this.value = value;
      this.sql = sql;
      this.defaultParam = defaultParam;
    }

    public String getValue() {
      return value;
    }

    public String getDefaultParam() {
      return defaultParam;
    }

    public String getSql() {
      return sql;
    }

    @Override
    public String toString() {
      return value;
    }

  }

  public enum Filters {
    TYPE("TYPE", "a.alertType IN :alertType ", "alertType", AlertType.PROJECT_ALERT.toString()),
    STATUS("STATUS", "a.status IN :status ", "status", ProjectServiceAlertStatus.JOB_FAILED.toString()),
    SEVERITY("SEVERITY", "a.severity IN :severity ", "severity", AlertSeverity.INFO.toString()),
    SERVICE("SERVICE", "a.service IN :service ", "service", ProjectServiceEnum.JOBS.toString()),
    CREATED("CREATED", "a.created = :created ","created",""),
    CREATED_GT("DATE_CREATED_GT", "a.created > :createdFrom ","createdFrom",""),
    CREATED_LT("DATE_CREATED_LT", "a.created < :createdTo ","createdTo","");

    private final String value;
    private final String sql;
    private final String field;
    private final String defaultParam;

    Filters(String value, String sql, String field, String defaultParam) {
      this.value = value;
      this.sql = sql;
      this.field = field;
      this.defaultParam = defaultParam;
    }

    public String getValue() {
      return value;
    }

    public String getDefaultParam() {
      return defaultParam;
    }

    public String getSql() {
      return sql;
    }

    public String getField() {
      return field;
    }

    @Override
    public String toString() {
      return value;
    }
  }
}
