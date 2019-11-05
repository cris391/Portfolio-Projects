DROP TABLE IF EXISTS posts cascade;
DROP TABLE IF EXISTS questions cascade;
DROP TABLE IF EXISTS answers cascade;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS stack_users;
DROP TABLE IF EXISTS app_users;
DROP TABLE IF EXISTS search_history;
DROP TABLE IF EXISTS markings;
DROP TABLE IF EXISTS annotations;
DROP TABLE IF EXISTS tags;

CREATE TABLE posts(
postid int, creationdate timestamp, score int, body text);

CREATE TABLE questions(
questionid int, closeddate timestamp, title text, acceptedanswerid int, postid int4);

CREATE TABLE answers(
answerid int4, parentid int4, postid int4);

CREATE TABLE comments(
commentid int, userid int, postid int, commentscore int, commenttext text, commentcreatedate timestamp);

CREATE TABLE stack_users(
userid int, usercreationdate timestamp, userdisplayname text, userlocation text, userage int);

CREATE TABLE app_users(
userid int, username text);

CREATE TABLE annotations(
userid int, questionid int, body text);

CREATE TABLE markings(
 userid int, questionid int);

CREATE TABLE search_history(
searchdate timestamp, userid text, queryText text);

CREATE TABLE tags(
value text, questionid int);

insert into posts(
postid, creationdate, score, body)
select distinct id, creationdate, score, body from posts_universal;

insert into questions(
questionid, closeddate, title, acceptedanswerid, postid)
select distinct id, closeddate, title, acceptedanswerid, id from posts_universal where posttypeid = 1;

insert into answers(answerid, parentid, postid)
select distinct id answerid, parentid, id from posts_universal where posttypeid = 2;

insert into comments(commentid, userid, postid, commentscore, commenttext, commentcreatedate) 
select distinct commentid, authorid, postid, commentscore, commenttext, commentcreatedate from comments_universal;

insert into stack_users(userid, usercreationdate, userdisplayname, userlocation, userage) 
select distinct ownerid, ownercreationdate, ownerdisplayname, ownerlocation, ownerage from posts_universal;

insert into app_users(userid, username)
select distinct ownerid, ownerdisplayname from posts_universal;

insert into tags(value, questionid)
select distinct tags, id from posts_universal where posttypeid = 1;

drop view if exists q_view;
create materialized view q_view as select q.questionid, p.creationdate, p.score, p.body, q.title, q.closeddate, q.acceptedanswerid 
from posts p
join questions q on q.questionid = p.postid;

drop view if exists a_view;
create materialized view a_view as select a.answerid, p.creationdate, p.score, p.body, a.parentid
from posts p
join answers a on a.answerid = p.postid;